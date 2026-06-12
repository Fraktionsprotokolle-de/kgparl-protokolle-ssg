package admin

import (
	"embed"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

//go:embed templates/dashboard.html
var templateFS embed.FS

// RegisterRoutes mounts all admin routes on the given router.
func RegisterRoutes(router *gin.Engine, cfg AdminConfig) {
	store, err := NewStore(cfg.DBPath)
	if err != nil {
		log.Fatalf("[admin] Failed to open database: %v", err)
	}

	scanner := NewFileScanner(cfg.ProjectRoot)
	builder := NewBuildManager(cfg.ProjectRoot, store)

	tmpl, err := template.ParseFS(templateFS, "templates/dashboard.html")
	if err != nil {
		log.Fatalf("[admin] Failed to parse dashboard template: %v", err)
	}

	adminGroup := router.Group("/admin", gin.BasicAuth(gin.Accounts{
		cfg.User: cfg.Password,
	}))

	// Dashboard HTML page
	adminGroup.GET("/", func(c *gin.Context) {
		c.Header("Cache-Control", "no-store")
		c.Status(http.StatusOK)
		c.Header("Content-Type", "text/html; charset=utf-8")
		if err := tmpl.Execute(c.Writer, nil); err != nil {
			log.Printf("[admin] template execute: %v", err)
		}
	})

	// API: File statistics
	adminGroup.GET("/api/stats", func(c *gin.Context) {
		c.Header("Cache-Control", "no-store")
		stats, err := scanner.GetStats()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, stats)
	})

	// API: Paginated file list
	adminGroup.GET("/api/files", func(c *gin.Context) {
		c.Header("Cache-Control", "no-store")
		sortField := c.DefaultQuery("sort", "modified")
		order := c.DefaultQuery("order", "desc")
		filter := c.DefaultQuery("filter", "")
		page := queryInt(c, "page", 1)
		perPage := queryInt(c, "per_page", 100)

		files, total, err := scanner.GetFiles(sortField, order, filter, page, perPage)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"data": files,
			"pagination": gin.H{
				"page":        page,
				"per_page":    perPage,
				"total":       total,
				"total_pages": (total + perPage - 1) / perPage,
			},
		})
	})

	// API: Trigger build
	adminGroup.POST("/api/build", func(c *gin.Context) {
		c.Header("Cache-Control", "no-store")
		var req BuildRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := ValidateTargets(req.Targets); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		user, _, _ := c.Request.BasicAuth()
		record, err := builder.StartBuild(req.Targets, req.Env, user)
		if err != nil {
			if err.Error() == "build already running" {
				c.JSON(http.StatusConflict, gin.H{"error": "A build is already running"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusAccepted, record)
	})

	// API: Current build status
	adminGroup.GET("/api/build/status", func(c *gin.Context) {
		c.Header("Cache-Control", "no-store")
		c.JSON(http.StatusOK, builder.Status())
	})

	// API: Build history
	adminGroup.GET("/api/build/history", func(c *gin.Context) {
		c.Header("Cache-Control", "no-store")
		limit := queryInt(c, "limit", 20)
		offset := queryInt(c, "offset", 0)

		builds, err := store.ListBuilds(limit, offset)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if builds == nil {
			builds = []BuildRecord{}
		}
		c.JSON(http.StatusOK, builds)
	})

	// API: Full build log
	adminGroup.GET("/api/build/:id/log", func(c *gin.Context) {
		c.Header("Cache-Control", "no-store")
		id, err := strconv.ParseInt(c.Param("id"), 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid build id"})
			return
		}

		build, err := store.GetBuild(id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": fmt.Sprintf("build %d not found", id)})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"id":     build.ID,
			"status": build.Status,
			"log":    build.LogOutput,
		})
	})

	log.Println("[admin] Admin dashboard enabled at /admin/")
}

func queryInt(c *gin.Context, key string, defaultVal int) int {
	if v := c.Query(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			return n
		}
	}
	return defaultVal
}

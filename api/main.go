package main

import (
	"bytes"
	"context"
	"embed"
	"fmt"
	"log"
	"net/http"
	"path/filepath"
"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
	"github.com/typesense/typesense-go/v2/typesense"
	"github.com/typesense/typesense-go/v2/typesense/api"
	"github.com/typesense/typesense-go/v2/typesense/api/pointer"

	"kgparl/api/admin"
)

var client *typesense.Client

//go:embed all:.env
var assetenv embed.FS

type CalenderEntry struct {
	Fraction  string         `json:"fraction"`
	StartDate string         `json:"startdate"`
	Name      string         `json:"name"`
	ID        string         `json:"id"`
	Items     []CalenderItem `json:"items"`
	Color     string         `json:"color"`
}

type CalenderItem struct {
	Name string `json:"name"`
	Link string `json:"link"`
}

// getStringField extracts a string field from a Typesense document
func getStringField(doc map[string]interface{}, field string) string {
	if val, ok := doc[field]; ok {
		if strVal, ok := val.(string); ok {
			return strVal
		}
	}
	return ""
}

// getItemsArray extracts and parses the items array from a Typesense document
func getItemsArray(doc map[string]interface{}) []CalenderItem {
	items := make([]CalenderItem, 0)

	if val, ok := doc["items"]; ok {
		// Check if it's an array of interfaces
		if arr, ok := val.([]interface{}); ok {
			for _, item := range arr {
				// Each item should be a map
				if itemMap, ok := item.(map[string]interface{}); ok {
					calItem := CalenderItem{
						Name: getStringField(itemMap, "name"),
						Link: getStringField(itemMap, "link"),
					}
					items = append(items, calItem)
				}
			}
		}
	}

	return items
}

func main() {
	env, err := assetenv.ReadFile(".env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Load environment variables from .env file
	viper.SetConfigName("env") // name of config file (without extension)
	viper.SetConfigType("env")
	err = viper.ReadConfig(bytes.NewBuffer(env))
	// Check if the config file was found
	if err != nil {
		log.Fatal("Error reading .env file")
	}

	// Allow environment variables to override embedded .env values
	viper.AutomaticEnv()

	// Get Typesense configuration from environment variables
	typesenseAddress := viper.GetString("TYPESENSE_HOST")
	typesensePort := viper.GetString("TYPESENSE_PORT")
	typesenseProtocol := viper.GetString("TYPESENSE_PROTOCOL")
	typesenseAPIKey := viper.GetString("TYPESENSE_API_KEY")

	// Check if API key is set
	if typesenseAPIKey == "" {
		log.Fatal("TYPESENSE_API_KEY is not set")
	}

	// build typesense server URL
	typesenseServer := typesenseProtocol + "://" + typesenseAddress + ":" + typesensePort

	// Initialize Typesense client
	client = typesense.NewClient(
		typesense.WithServer(typesenseServer),
		typesense.WithAPIKey(typesenseAPIKey),
	)

	// Set mode to release
	gin.SetMode(gin.ReleaseMode)

	// Set up Gin router
	router := gin.Default()

	// Define routes
	router.GET("/persons", getPersons)
	router.GET("/parties", getParties)
	router.GET("/periods", getPeriods)
	router.GET("/person/:id", getPerson)
	router.GET("/calendar", getCalender)
	router.GET("/info", getInfo)
	// Admin dashboard (only enabled if credentials are configured)
	adminUser := viper.GetString("ADMIN_USER")
	adminPass := viper.GetString("ADMIN_PASSWORD")
	projectRoot := viper.GetString("PROJECT_ROOT")
	if adminUser != "" && adminPass != "" {
		if projectRoot == "" {
			log.Println("[admin] Warning: PROJECT_ROOT not set, admin dashboard disabled")
		} else {
			admin.RegisterRoutes(router, admin.AdminConfig{
				User:        adminUser,
				Password:    adminPass,
				ProjectRoot: projectRoot,
				DBPath:      filepath.Join(projectRoot, "api", "admin_builds.db"),
			})
		}
	} else {
		log.Println("[admin] ADMIN_USER/ADMIN_PASSWORD not set, admin dashboard disabled")
	}

	// Start the server
	port := viper.GetString("CHIPORT")
	log.Printf("Starting server on port %s", port)
	log.Fatal(router.Run(":" + port))
}

// getInfo returns information about the API
func getInfo(c *gin.Context) {
	info := gin.H{
		"name":    "KGParl",
		"version": "0.1.0",
	}

	c.JSON(http.StatusOK, info)
}

// getPersons returns a paginated list of persons
// Supports: /persons?page=1&per_page=50&q=Müller&letter=M&found=true
func getPersons(c *gin.Context) {
	// Parse pagination parameters
	page := 1
	if pageParam := c.Query("page"); pageParam != "" {
		if _, err := fmt.Sscanf(pageParam, "%d", &page); err == nil {
			if page < 1 {
				page = 1
			}
		}
	}

	perPage := 50 // Default
	if perPageParam := c.Query("per_page"); perPageParam != "" {
		if _, err := fmt.Sscanf(perPageParam, "%d", &perPage); err == nil {
			if perPage < 1 {
				perPage = 1
			}
			if perPage > 250 {
				perPage = 250 // Typesense max
			}
		}
	}

	// Search query (default: all)
	q := c.DefaultQuery("q", "*")

	searchParameters := &api.SearchCollectionParams{
		Q:       pointer.String(q),
		QueryBy: pointer.String("surname,forename,reg"),
		PerPage: pointer.Int(perPage),
		Page:    pointer.Int(page),
		SortBy:  pointer.String("surname:asc,forename:asc"),
	}

	// Optional filter by letter
	if letter := c.Query("letter"); letter != "" {
		searchParameters.FilterBy = pointer.String(fmt.Sprintf("letter:=%s", letter))
	}

	// Optional filter by found status
	if found := c.Query("found"); found != "" {
		filterBy := fmt.Sprintf("found:=%s", found)
		if searchParameters.FilterBy != nil {
			filterBy = *searchParameters.FilterBy + " && " + filterBy
		}
		searchParameters.FilterBy = pointer.String(filterBy)
	}

	searchResult, err := client.Collection("kgparl_persons").
		Documents().
		Search(context.Background(), searchParameters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if searchResult.Found == nil || *searchResult.Found == 0 {
		c.JSON(http.StatusOK, gin.H{
			"data":       []interface{}{},
			"pagination": gin.H{
				"page":        page,
				"per_page":    perPage,
				"found":       0,
				"total_pages": 0,
			},
		})
		return
	}

	// Calculate pagination metadata
	found := int(*searchResult.Found)
	totalPages := (found + perPage - 1) / perPage

	response := gin.H{
		"data": searchResult.Hits,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"found":       found,
			"total_pages": totalPages,
		},
	}

	c.JSON(http.StatusOK, response)
}

// getParties returns a list of unique parties from the kgparl collection
func getParties(c *gin.Context) {
	searchParameters := &api.SearchCollectionParams{
		Q:        pointer.String("*"),
		QueryBy:  pointer.String("title"),
		FacetBy:  pointer.String("party"),
		MaxFacetValues: pointer.Int(100),
		PerPage:  pointer.Int(0), // We only need facets, not documents
	}

	searchResult, err := client.Collection("kgparl").
		Documents().
		Search(context.Background(), searchParameters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Extract unique parties from facet counts
	parties := []gin.H{}
	if searchResult.FacetCounts != nil {
		for _, facet := range *searchResult.FacetCounts {
			if *facet.FieldName == "party" {
				for _, count := range *facet.Counts {
					parties = append(parties, gin.H{
						"name":  *count.Value,
						"count": *count.Count,
					})
				}
			}
		}
	}

	c.JSON(http.StatusOK, parties)
}

// getPeriods returns a list of unique periods from the kgparl collection
func getPeriods(c *gin.Context) {
	searchParameters := &api.SearchCollectionParams{
		Q:        pointer.String("*"),
		QueryBy:  pointer.String("title"),
		FacetBy:  pointer.String("period"),
		MaxFacetValues: pointer.Int(100),
		PerPage:  pointer.Int(0), // We only need facets, not documents
	}

	searchResult, err := client.Collection("kgparl").
		Documents().
		Search(context.Background(), searchParameters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Extract unique periods from facet counts
	periods := []gin.H{}
	if searchResult.FacetCounts != nil {
		for _, facet := range *searchResult.FacetCounts {
			if *facet.FieldName == "period" {
				for _, count := range *facet.Counts {
					periods = append(periods, gin.H{
						"name":  *count.Value,
						"count": *count.Count,
					})
				}
			}
		}
	}

	c.JSON(http.StatusOK, periods)
}

// getPerson returns a person identified by the id
func getPerson(c *gin.Context) {
	id := c.Param("id")
	document, err := client.Collection("kgparl_persons").Document(id).Retrieve(context.Background())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, document)
}

// getCalender returns all protocols within the given date range (optional)
// Accepts from and to as query parameters: /calendar?from=2020-01-01&to=2020-12-31
// Supports pagination: /calendar?page=1&per_page=50
func getCalender(c *gin.Context) {
	from := c.Query("from")
	to := c.Query("to")

	// Parse pagination parameters
	page := 1
	if pageParam := c.Query("page"); pageParam != "" {
		if p, err := fmt.Sscanf(pageParam, "%d", &page); err == nil && p == 1 {
			if page < 1 {
				page = 1
			}
		}
	}

	perPage := 250 // Default to max
	if perPageParam := c.Query("per_page"); perPageParam != "" {
		if p, err := fmt.Sscanf(perPageParam, "%d", &perPage); err == nil && p == 1 {
			if perPage < 1 {
				perPage = 1
			}
			if perPage > 250 {
				perPage = 250 // Typesense max
			}
		}
	}

	searchParameters := &api.SearchCollectionParams{
		Q:       pointer.String("*"),
		QueryBy: pointer.String("date"),
		PerPage: pointer.Int(perPage),
		Page:    pointer.Int(page),
	}

	// Add date filter only if both from and to parameters are provided
	if from != "" && to != "" {
		searchParameters.FilterBy = pointer.String(fmt.Sprintf("date:>=%s && date:<=%s", from, to))
	}

	searchResult, err := client.Collection("kgparl").
		Documents().
		Search(context.Background(), searchParameters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// reformat response to new structure
	// init array
	responseArray := make([]CalenderEntry, 0, len(*searchResult.Hits))

	// reformat response to CalenderEntry structure
	for _, hit := range *searchResult.Hits {
		document := *hit.Document

		// Extract fields from the Typesense document
		ce := CalenderEntry{
			Fraction:  getStringField(document, "party"),
			StartDate: getStringField(document, "date"),
			Name:      getStringField(document, "title"),
			ID:        getStringField(document, "id"),
			Color:     getStringField(document, "color"),
			Items:     getItemsArray(document),
		}

		responseArray = append(responseArray, ce)
	}

	// Return response with pagination metadata
	found := int(*searchResult.Found)
	totalPages := (found + perPage - 1) / perPage

	response := gin.H{
		"data": responseArray,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"found":       found,
			"total_pages": totalPages,
		},
	}

	c.JSON(http.StatusOK, response)
}


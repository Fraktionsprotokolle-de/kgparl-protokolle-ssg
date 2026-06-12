<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="/" name="nav_bar">
        <header class=" text-white py-3">
            <div class="container">
                <div class="row">
                    <div class="col-6 text-start">
                        <div class="heading">
                            <h1>Fraktionen im Deutschen Bundestag 1949-2005</h1>
                            <span>»Die historisch-digitale Quellenedition der Protokolle der
                                Fraktionen und Gruppen des Deutschen Bundestags von 1949 bis 2005«</span>
                        </div>
                    </div>
                    <div class="col-6 text-end">
                        <div>
                            <!-- Add your logo here, for example: -->
                            <a type="button" class="btn" title="Startseite" href="index.html">
                                <img
                                    class="logo"
                                    height="80"
                                    src="./images/KGParl_title.png"
                                    alt="logo"
                                />
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </header>

        <!-- Rest of your existing content -->

        <nav class="navbar navbar-expand-lg navbar-light bg-light">
            <div class="container">
                <button
                    class="navbar-toggler"
                    type="button"
                    data-toggle="collapse"
                    data-target="#navbarNav"
                    aria-controls="navbarNav"
                    aria-expanded="false"
                    aria-label="Toggle navigation"
                >
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav me-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="#">Startseite</a>
                        </li>
                        <li class="nav-item dropdown">
                            <a
                                class="nav-link dropdown-toggle"
                                href="#"
                                id="projektDropdown"
                                role="button"
                                data-toggle="dropdown"
                                aria-expanded="false"
                            >Projekt</a>
                            <ul class="dropdown-menu" aria-labelledby="projektDropdown">
                                <li>
                                    <a class="dropdown-item" href="#">Projekt</a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="#">Aktuelles</a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="#">Editionshinweise</a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="#">Forschungsrelevanz</a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="#"
                                    >Mitarbeiterinnen und
                                        Mitarbeiter</a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="#">Editionsbeirat</a>
                                </li>
                            </ul>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/kalender.html">Kalender</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/einleitungen.html">Einleitungen</a>
                        </li>
                        <li class="nav-item dropdown">
                            <a
                                class="nav-link dropdown-toggle"
                                href="#"
                                id="verzeichnisseDropdown"
                                role="button"
                                data-toggle="dropdown"
                                aria-expanded="false"
                            >Verzeichnisse</a>
                            <ul class="dropdown-menu" aria-labelledby="verzeichnisseDropdown">
                                <li>
                                    <a class="dropdown-item" href="personenregister.html">
                                        Personenregister</a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="literaturverzeichnis.html">
                                        Literaturverzeichnis</a>
                                </li>
                            </ul>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#">Hilfe</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link"
                                href="https://github.com/Fraktionsprotokolle-de/fraktionsprotokolle_web"
                                target="_blank" aria-label="GitHub">GitHub</a>
                        </li>
                    </ul>
                    <div class="navbar-nav language-switcher d-none">
                        <button type="button" class="nav-link" href="#"> deutsch <svg
                                xmlns="http://www.w3.org/2000/svg"
                                width="24"
                                height="16"
                                viewBox="0 0 24 16"
                            >
                                <rect width="24" height="5.33" fill="#000000" />
                                <rect width="24" height="5.33" y="5.33" fill="#FF0000" />
                                <rect width="24" height="5.33" y="10.67" fill="#FFD700" />
                            </svg>
                        </button>
                        <button type="button" class="nav-link" href="#"> english <svg
                                width="24"
                                height="16"
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 60 40"
                            >
                                <!-- Background -->
                                <rect width="60" height="40" fill="#00247d" />

                                <!-- Red Cross -->
                                <rect x="26" width="8" height="40" fill="#cf142b" />
                                <rect y="16" width="60" height="8" fill="#cf142b" />

                                <!-- White Borders around the Cross -->
                                <rect x="24" width="4" height="40" fill="#fff" />
                                <rect x="32" width="4" height="40" fill="#fff" />
                                <rect y="14" width="60" height="4" fill="#fff" />
                                <rect y="22" width="60" height="4" fill="#fff" />

                                <!-- Diagonal Red Cross -->
                                <polygon
                                    points="0,0 4,0 30,18 30,22 0,40 0,36 24,20 0,4"
                                    fill="#cf142b"
                                />
                                <polygon
                                    points="60,0 56,0 30,18 30,22 60,40 60,36 36,20 60,4"
                                    fill="#cf142b"
                                />

                                <!-- White Borders around Diagonal Cross -->
                                <polygon
                                    points="0,0 2,0 30,17 30,23 0,40 0,38 27,20 0,2"
                                    fill="#fff"
                                />
                                <polygon
                                    points="60,0 58,0 30,17 30,23 60,40 60,38 33,20 60,2"
                                    fill="#fff"
                                />
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        </nav>
    </xsl:template>
</xsl:stylesheet>

# Sample application profile, customize this and related files for your own custom systems

# API Key, must match API server settings
#
DEFINES+= API_KEY=\\\"ThisIsASampleAPIKeyAndMUSTBeChanged\\\"

# Development server
#
DEFINES+= API_SERVER_SANDBOX=\\\"http://localhost/v3\\\"

# Production should run on secure https !
#
DEFINES+= API_SERVER_PRODUCTION=\\\"http://localhost/v3/\\\"

# Application name, domain & organization
#
DEFINES+= APP_DOMAIN=\\\"dummy.domain.change.this\\\"
DEFINES+= APP_ORG=\\\"SampleOrgChangeThis\\\"
DEFINES+= APP_NAME=\\\"ApplicationNameChangeThis\\\"


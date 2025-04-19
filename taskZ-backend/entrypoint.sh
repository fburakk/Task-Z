#!/bin/bash

# Wait for the database to be ready
sleep 10

# Start the application
dotnet CleanArchitecture.WebApi.dll 
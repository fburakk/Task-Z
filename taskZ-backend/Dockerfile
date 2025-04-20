FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["CleanArchitecture/CleanArchitecture.WebApi/CleanArchitecture.WebApi.csproj", "CleanArchitecture.WebApi/"]
COPY ["CleanArchitecture/CleanArchitecture.Infrastructure/CleanArchitecture.Infrastructure.csproj", "CleanArchitecture.Infrastructure/"]
COPY ["CleanArchitecture/CleanArchitecture.Core/CleanArchitecture.Core.csproj", "CleanArchitecture.Core/"]
COPY ["CleanArchitecture/CleanArchitecture.Application/CleanArchitecture.Core.csproj", "CleanArchitecture.Application/"]
RUN dotnet restore "CleanArchitecture.WebApi/CleanArchitecture.WebApi.csproj"
COPY . .
WORKDIR "/src/CleanArchitecture/CleanArchitecture.WebApi"
RUN dotnet build "CleanArchitecture.WebApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "CleanArchitecture.WebApi.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "CleanArchitecture.WebApi.dll"] 
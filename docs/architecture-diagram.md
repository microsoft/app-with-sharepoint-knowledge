---
config:
  theme: mc
---
architecture-beta
    group github(database)[GitHub]
        service sourceRepo(fa:file)[Template Repo] in github
    group azure(cloud)[Azure]
        service containerapp(azure:container-registries)[Sample App deployed in Container App] in azure
        service containerregistry(azure:worker-container-app)[Azure Container Registry] in azure
        group foundry(cloud)[Azure AI Foundry] in azure
        service foundrymodel(server)[GPT and other models] in foundry

    service user(fa:user)[User receives generated compliance report]
    group Graph(cloud)[Graph]
        service graphAPI(database)[Copilot Retrieval API] in Graph    
    group M365(cloud)[M365]
        service sharepoint(database)[SharePoint] in M365
    
    graphAPI:R <--> L:sharepoint
    containerapp:B <--> T:graphAPI

    service azd(azure:dev-console)[azd]
    
    containerregistry:R -- L:containerapp
    containerapp:R <--> L:foundrymodel

    sourceRepo:R --> L:azd
    containerregistry:T <-- B:azd
    user:L --> R:azd
    user:B <-- T:containerapp

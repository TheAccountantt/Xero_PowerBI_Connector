# Xero Power BI Connector

This repository contains a custom connector for Power BI using the Power Query SDK. The connector allows you to connect to Xero, a popular accounting software, and retrieve data for analysis in Power BI.

## Prerequisites

1. **Xero Account**: You will need a free Xero account to access the demo company.
2. **Developer App**: Log in to the [Xero Developer Portal](https://developer.xero.com/) and create a mobile desktop app to obtain the `client_id`.

## Setup Instructions

1. **Clone the Repository**:
    ```sh
    git clone https://github.com/yourusername/ZeroConnector.git
    cd ZeroConnector
    ```

2. **Open in Visual Studio Code**:
    Open the project in Visual Studio Code to edit and test the connector.

3. **Configure Settings**:
    Ensure the `.vscode/settings.json` file is correctly configured:
    ```json
    {
      "powerquery.sdk.defaultQueryFile": "${workspaceFolder}\\${workspaceFolderBasename}.query.pq",
      "powerquery.sdk.defaultExtension": "${workspaceFolder}\\bin\\AnyCPU\\Debug\\${workspaceFolderBasename}.mez",
      "powerquery.general.mode": "SDK"
    }
    ```

4. **Build the Connector**:
    Run the build command to generate the `.mez` file:
    ```sh
    msbuild ZeroConnector.proj
    ```

5. **Deploy the Connector**:
    Copy the generated `ZeroConnector.mez` file from the `bin/AnyCPU/Debug/` directory to your Power BI Custom Connectors directory.

## Testing the Connector

1. **Write Queries**:
    Use the `ZeroConnector.query.pq` file to write queries for testing your data connector:
    ```pq
    let
        source = ZeroConnector.Contents(),
        org = source{0}[tenantId],
        Contacts = ZeroConnector.Contents("https://api.xero.com/api.xro/2.0/Contacts", org),
        Conts = List.Count(Contacts[Contacts])
    in
        Conts
    ```

2. **Run Queries**:
    Execute the queries in Power BI to test the connector functionality.

## Additional Information

- **OAuth Flow**: The connector uses OAuth for authentication. Refer to the `ZeroConnector.pq` file for details on the OAuth implementation.
- **Icons**: Custom icons for the connector are defined in the `ZeroConnector.pq` file and included in the project.

For more information, visit the [Power BI Custom Connectors documentation](https://docs.microsoft.com/en-us/power-bi/connect-data/service-connectors-custom).

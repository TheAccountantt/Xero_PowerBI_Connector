[Version = "1.0.0"]
section ZeroConnector;

client_id = "4E7B0EC068DA412492991FD63BA32B21";
required_scopes = "openid profile offline_access email accounting.transactions.read accounting.contacts.read";

windowWidth = 600;
windowHeight = 800;

redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
base_url = "https://api.xero.com";

// Data Source Kind description
ZeroConnector = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh,
            Label = Extension.LoadString("ButtonTitle")
        ]
    ],
    Label = Extension.LoadString("ButtonTitle"),
    TestConnection = (dataSourcePath) => {"ZeroConnector.Contents"},
    Functions = { 
        ZeroConnector.Contents = [
            TestConnection = (dataSourcePath) => {"ZeroConnector.Contents"}
        ]
    }
];

// OAuth flow
StartLogin = (resourceUrl, state, display) =>
    let
        plainTextCodeVerifier = Text.NewGuid() & Text.NewGuid(),
        bEnc = (s) => Text.Replace(Text.Replace(Text.BeforeDelimiter(Binary.ToText(s, BinaryEncoding.Base64), "="),"+","-"),"/","_"),
        codeVerifier = bEnc(Crypto.CreateHash(CryptoAlgorithm.SHA256, Text.ToBinary(plainTextCodeVerifier))),
        AuthorizeUrl = "https://login.xero.com/identity/connect/authorize?" & Uri.BuildQueryString([
            response_type = "code",
            client_id = client_id,
            redirect_uri = redirect_uri,
            scope = required_scopes,
            state = state,
            code_challenge = codeVerifier,
            code_challenge_method = "S256"
        ])
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = windowHeight,
            WindowWidth = windowWidth,
            Context = plainTextCodeVerifier
        ];

FinishLogin = (context, callbackUri, state) => 
    let
        Parts = Uri.Parts(callbackUri)[Query],
        Code = if Record.HasFields(Parts, "code") then Parts[code] else error "Authorization code not found in callback URI."
    in 
        TokenMethod(Code, "authorization_code", context);

TokenMethod = (code, grant_type, optional verifier) =>
    let
        codeVerifier = if (verifier <> null) then [code_verifier = verifier] else [],
        codeParameter = if (grant_type = "authorization_code") then [code = code] else [refresh_token = code],
        query = codeVerifier & codeParameter & [
            client_id = client_id,
            grant_type = grant_type,
            redirect_uri = redirect_uri
        ],
        Response = Web.Contents("https://identity.xero.com/connect/token", 
        [
            Content = Text.ToBinary(Uri.BuildQueryString(query)),
            Headers = [
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json"
            ],
            ManualStatusHandling = {400, 401, 402, 403, 404}
        ]),
        Parts = Json.Document(Response)
    in
        if (Record.HasFields(Parts, "error")) then 
            error Error.Record(Parts[error], Parts[error_description]?) 
        else 
            Parts;

Refresh = (resourceUrl, refresh_token) => TokenMethod(refresh_token, "refresh_token");

// Data Source UI publishing description
ZeroConnector.Publish = [
    Beta = true,
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    SourceImage = ZeroConnector.Icons,
    SourceTypeImage = ZeroConnector.Icons,
    Category = "Other",
    LearnMoreUrl = "https://powerbi.microsoft.com/"
];

// Icons definition
ZeroConnector.Icons = [
    Icon16 = { Extension.Contents("ZeroConnector16.png"), Extension.Contents("ZeroConnector20.png"), Extension.Contents("ZeroConnector24.png"), Extension.Contents("ZeroConnector32.png") },
    Icon32 = { Extension.Contents("ZeroConnector32.png"), Extension.Contents("ZeroConnector40.png"), Extension.Contents("ZeroConnector48.png"), Extension.Contents("ZeroConnector64.png") }
];

// Main data source function
[DataSource.Kind="ZeroConnector", Publish="ZeroConnector.Publish"]
shared ZeroConnector.Contents = Value.ReplaceType(Zero.Contents, type function (optional endpoint as text, optional tenantId as text, optional additionalParams as record) as any);

Zero.Contents = (optional endpoint as text, optional tenantId as text, optional additionalParams as record) =>
    let
        connectionsPath = base_url & "/connections",
        defaultHeaders = [
            #"Accept" = "application/json"
        ],
        url = if endpoint = null then connectionsPath else endpoint,
        response = Web.Contents(url, [
            Headers = defaultHeaders & (if tenantId = null then [] else [#"xero-tenant-id" = tenantId]),
            ManualStatusHandling = {400, 401, 402, 403, 404}
        ]),
        json = Json.Document(response)
    in
        json;
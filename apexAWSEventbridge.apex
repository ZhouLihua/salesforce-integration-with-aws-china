public with sharing class EventSender {
    // TODO, add other parameters here, like EventBusName https://docs.aws.amazon.com/eventbridge/latest/APIReference/API_PutEventsRequestEntry.html
    public class EventEntry {
        private String Detail;
        private String Source;
        private String DetailType;
        public EventEntry(String detail){
            this.Detail = detail;
            this.Source = 'com.mycompany.salesforce';
            this.DetailType = 'com.mycompany.salesforce';
        }
    }

    public class AwsException extends Exception {}

    private static String access_key;
    private static String secret_key;
    private static String aws_region;
    private static String aws_account_id;
    private static String host {get;set;}
    private static String endpoint {get;set;}
    private static String request_parameters {get;set;}

    private static final String aws_service = 'events';
    private static final String content_type = 'application/x-amz-json-1.1';

    // Create a date for headers and the credential string
    private static final Datetime now = Datetime.now();
    private static final String amz_date = now.formatGmt('YMMdd') + 'T' + now.formatGmt('HHmmss') + 'Z';
    private static final String date_stamp = now.formatGmt('YMMdd');


    /**
     * Load AWS credentials from Custom Metadata Types: https://help.salesforce.com/articleView?id=custommetadatatypes_about.htm&type=5
     * TODO: load aws keys from Salesforce Custom Metadata
     */
    private static void loadAwsKeys(){
        access_key= <access_key>;
        secret_key= <secret_key>;
        aws_account_id= <aws account id>;
        aws_region= 'cn-north-1';
              
        EventSender.aws_region = aws_region;
        EventSender.aws_account_id = aws_account_id;
        EventSender.access_key =  access_key;
        EventSender.secret_key = secret_key;

        // TODO: handle different regions, this is only for aws China regions
        EventSender.host = aws_service + '.' + aws_region + '.amazonaws.com.cn';
        EventSender.endpoint = 'https://' + EventSender.host + '/';
    }


    /**
     * @param messageBody
     */
    public static void SendMessage(String messageBody) {
        if (messageBody == null) {
            throw new AwsException('Body is mandatory');
        }
        loadAwsKeys();

        List<EventEntry> eventEntries = new List<EventEntry>();
        EventEntry entry = new EventEntry(messageBody);
        eventEntries.add(entry);
        Map<String, List<EventEntry>> entries = new Map<String, List<EventEntry>>();
        entries.put('Entries', eventEntries);


        EventSender.aws_region = aws_region;
        EventSender.aws_account_id = aws_account_id;
        EventSender.request_parameters = JSON.serialize(entries);
        EventSender.host = aws_service + '.' + aws_region + '.amazonaws.com.cn';
        EventSender.endpoint = 'https://' + host + '/';
        System.debug('endpoint: '+EventSender.endpoint);

        String canonical_request = EventSender.createCanonicalRequest();
        String string_to_sign = EventSender.createTheStringToSign(canonical_request);
        String signature = EventSender.calculateTheSignature(string_to_sign);
        String authorization_header = EventSender.addSigningInfoToTheRequest(signature);

        EventSender.sendRequest(authorization_header, amz_date, request_parameters, endpoint);
    }


    /**
     * @param messageBody
     */
    public static void SendMessageBatch(List<String> messageBody) {
        if (messageBody.size() > 10) {
            throw new AwsException('Too many entries. the maximum entries is 10');
        }
        loadAwsKeys();
 
        List<EventEntry> eventEntries = new List<EventEntry>();
        for(String body: messageBody){
            EventEntry entry = new EventEntry(body);
            eventEntries.add(entry);
        }

        Map<String, List<EventEntry>> entries = new Map<String, List<EventEntry>>();
        entries.put('Entries', eventEntries);

        EventSender.aws_region = aws_region;
        EventSender.aws_account_id = aws_account_id;
        EventSender.request_parameters = JSON.serialize(entries);
        EventSender.host = aws_service + '.' + aws_region + '.amazonaws.com.cn';
        EventSender.endpoint = 'https://' + host + '/';
        System.debug('endpoint: '+EventSender.endpoint);

        String canonical_request = EventSender.createCanonicalRequest();
        String string_to_sign = EventSender.createTheStringToSign(canonical_request);
        String signature = EventSender.calculateTheSignature(string_to_sign);
        String authorization_header = EventSender.addSigningInfoToTheRequest(signature);

        EventSender.sendRequest(authorization_header, amz_date, request_parameters, endpoint);
    }

    /**
     * @param body
     */
    @future(Callout=true)
    public static void sendRequest(String authorization_header, String amz_date, String request_body, String endpoint) {

        // assemble request https://docs.aws.amazon.com/eventbridge/latest/APIReference/API_PutEvents.html#API_PutEvents_RequestParameters
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', content_type);
        request.setHeader('Authorization', authorization_header);
        request.setHeader('x-amz-date', amz_date);
        request.setHeader('X-Amz-Target', 'AWSEvents.PutEvents');
        
        System.debug('request body: ' + request_body);
        // Set the body as a JSON object
        request.setBody(request_body);

        Http http = new Http();
        HttpResponse response = http.send(request);
        System.debug(response.getBody());
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                    response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug('message sent successfully to event bridge');
            System.debug(response.getBody());
        } 
    }

     // http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
    private static String createCanonicalRequest() {

        String host = aws_service + '.' + aws_region + '.amazonaws.com.cn';

        // Step 1 is to define the verb (GET, POST, etc.)
        String method = 'POST';

        // Step 2: Create canonical URI--the part of the URI from domain to query
        String canonical_uri = '/';

        // Step 3: Create the canonical query string. In this example, request
        // parameters are passed in the body of the request and the query string  is blank.
        String canonical_querystring = EncodingUtil.urlEncode('', 'UTF-8');

        // Step 4: Create the canonical headers. Header names must be trimmed
        // and lowercase, and sorted in code point order from low to high.
        // Note that there is a trailing n
        String canonical_headers = 'content-type:' + content_type + '\n' + 'host:' + host + '\n' + 'x-amz-date:' + amz_date + '\n';

        // Step 5: Create the list of signed headers. This lists the headers
        // in the canonical_headers list, delimited with ";" and in alpha order.
        String signed_headers = 'content-type;host;x-amz-date';

        // Step 6: Create payload hash. In this example, the payload
        // (body of the request) contains the request parameters.
        String payload_hash = hashLibSha256(request_parameters);

        // Step 7: Combine elements to create canonical request
        String canonical_request =
                        method + '\n' +
                        canonical_uri + '\n' +
                        canonical_querystring + '\n' +
                        canonical_headers + '\n' +
                        signed_headers + '\n' +
                        payload_hash;

        return canonical_request;
    }

    private static String createTheStringToSign(String canonical_request) {
        // Match the algorithm to the hashing algorithm you use,
        // either SHA-1 or SHA-256 (recommended)
        String algorithm = 'AWS4-HMAC-SHA256';
        String credential_scope = date_stamp + '/' + aws_region + '/' + aws_service + '/' + 'aws4_request';
        String string_to_sign =
                        algorithm + '\n' +
                        amz_date + '\n' +
                        credential_scope + '\n' +
                        hashLibSha256(canonical_request);
        return string_to_sign;
    }

    private static String calculateTheSignature(String string_to_sign) {
        // Create the signing key using the function defined above.
        Blob signing_key = getSignatureKey(secret_key, date_stamp, aws_region, aws_service);

        // Sign the string_to_sign using the signing_key
        String signature = EncodingUtil.convertToHex(Crypto.generateMac('HmacSHA256', Blob.valueof(string_to_sign), signing_key));
        return signature;
    }

    private static String addSigningInfoToTheRequest(String signature) {
        String credential_scope = date_stamp + '/' + aws_region + '/' + aws_service + '/' + 'aws4_request';
        String signed_headers = 'content-type;host;x-amz-date';
        String algorithm = 'AWS4-HMAC-SHA256';
        // Put the signature information in a header named Authorization.
        String authorization_header = algorithm + ' ' + 'Credential=' + access_key + '/' + credential_scope + ', ' + 'SignedHeaders=' + signed_headers + ', ' + 'Signature=' + signature;
        return authorization_header;
    }

    private static Blob getSignatureKey(String key, String date_stamp, String region_name, String service_name) {
        Blob kDate = sign(date_stamp, Blob.valueof('AWS4' + key));
        Blob kRegion = sign(region_name, kDate);
        Blob kService = sign(service_name, kRegion);
        Blob kSigning = sign('aws4_request', kService);
        return kSigning;
    }

    private static Blob sign(String data, Blob key) {
        return Crypto.generateMac('HmacSHA256', Blob.valueOf(data), key);
    }

    private static String hashLibSha256(String message) {
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(message)));
    }
}
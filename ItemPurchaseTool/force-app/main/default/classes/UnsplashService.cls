public with sharing class UnsplashService {
    // Access key for Unsplash API
    private static final String ACCESS_KEY = 'nreFjY6W16Ou1_5xAXD-ctLCBTa7ycHSCPj27c0SjcA';

    @AuraEnabled
    public static String getItemImageUrl(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return '';
        }

        String encodedQuery = EncodingUtil.urlEncode(searchTerm, 'UTF-8');
        String endpoint = 'https://api.unsplash.com/search/photos?query=' + encodedQuery + '&per_page=1';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        
        request.setHeader('Authorization', 'Client-ID ' + ACCESS_KEY);
        request.setHeader('Content-Type', 'application/json');

        try {
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                // Parse the JSON payload
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> results = (List<Object>) jsonResponse.get('results');
                
                if (!results.isEmpty()) {
                    // Extract the first photo object
                    Map<String, Object> firstResult = (Map<String, Object>) results[0];
                    Map<String, Object> urls = (Map<String, Object>) firstResult.get('urls');
                    
                    return (String) urls.get('small');
                }
            } else {
                System.debug('Unsplash API Error: ' + response.getStatusCode() + ' ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('HTTP Callout Exception: ' + e.getMessage());
        }
        
        // Fallback placeholder image if the API call fails or finds no results
        return 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=500';
    }
}
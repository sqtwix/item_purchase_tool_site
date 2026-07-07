@isTest
private class UnsplashServiceTest {
    
    @isTest
    static void testGetImageUrlSuccess() {
        // Tell Salesforce to use our fake internet connection instead of the real one
        Test.setMock(HttpCalloutMock.class, new UnsplashCalloutMock());
        
        Test.startTest();
        String imageUrl = UnsplashService.getItemImageUrl('Coffee Mug');
        Test.stopTest();
        
        System.assertEquals('https://images.unsplash.com/mock-image', imageUrl, 'Image URL should match the mock.');
    }

    @isTest
    static void testGetImageUrlBlank() {
        // Testing the safety check for an empty search
        String imageUrl = UnsplashService.getItemImageUrl('');
        System.assertEquals('', imageUrl, 'Blank search should return a blank string.');
    }

    @isTest
    static void testCreateNewItem() {
        // We must also mock the internet here because createNewItem calls the UnsplashService!
        Test.setMock(HttpCalloutMock.class, new UnsplashCalloutMock());
        
        // Create a Manager user so the backend security check passes
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User managerUser = new User(
            Alias = 'mgr2', Email='manager2@truesolv.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='manager2' + DateTime.now().getTime() + '@truesolv.com',
            IsManager__c = true
        );
        insert managerUser;

        System.runAs(managerUser) {
            Test.startTest();
            Item__c newItem = ItemPurchaseController.createNewItem(
                'Test Mouse', 'Wireless', 'Type 1', 'Family 1', 50.00, 25
            );
            Test.stopTest();
            
            System.assertNotEquals(null, newItem.Id, 'The new item should have been successfully saved to the database.');
            System.assertEquals('https://images.unsplash.com/mock-image', newItem.Image__c, 'The image URL should be automatically applied.');
        }
    }
}
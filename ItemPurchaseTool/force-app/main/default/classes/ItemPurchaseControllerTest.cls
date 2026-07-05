@isTest
public with sharing class ItemPurchaseControllerTest {
    // Mock data setup for testing (aka fixtures)
    @testSetup
    static void setupTestData() {
        // Create an Account
        Account testAccount = new Account(Name = 'Test TrueSolv Account');
        insert testAccount;

        // Create Items
        List<Item__c> items = new List<Item__c>{
            new Item__c(Name = 'Laptop', Description__c = 'Fast PC', Type__c = 'Hardware', Family__c = 'Tech', Price__c = 1000, AvailableQuantity__c = 10),
            new Item__c(Name = 'Mouse', Description__c = 'Wireless', Type__c = 'Accessories', Family__c = 'Tech', Price__c = 50, AvailableQuantity__c = 0) // Out of stock
        };
        insert items;

        // Create a Manager User
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User managerUser = new User(
            Alias = 'mgr', Email='manager@truesolv.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='manager' + DateTime.now().getTime() + '@truesolv.com',
            IsManager__c = true
        );
        insert managerUser;
    }

    // Test the Item Filter Engine
    @isTest
    static void testGetItems() {
        Test.startTest();
        List<Item__c> results = ItemPurchaseController.getItems('Laptop', 'Tech', 'Hardware');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return exactly 1 in-stock item.');
        System.assertEquals('Laptop', results[0].Name, 'The returned item should be the Laptop.');
    }

    // Test the Manager Permission Check
    @isTest
    static void testIsUserManager() {
        User manager = [SELECT Id FROM User WHERE Email = 'manager@truesolv.com' LIMIT 1];
        
        System.runAs(manager) {
            Test.startTest();
            Boolean isMgr = ItemPurchaseController.isUserManager();
            Test.stopTest();
            
            System.assertEquals(true, isMgr, 'The user should be identified as a manager.');
        }
    }

    // Test a Successful Checkout
    @isTest
    static void testProcessCheckoutSuccess() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c laptop = [SELECT Id, Price__c FROM Item__c WHERE Name = 'Laptop' LIMIT 1];

        // Create the JSON payload that the LWC would normally send
        String payload = '[{"itemId":"' + laptop.Id + '", "quantity":2, "unitPrice":' + laptop.Price__c + '}]';

        Test.startTest();
        Id purchaseId = ItemPurchaseController.processCheckout(acc.Id, payload);
        Test.stopTest();

        // Verify the database updated correctly
        System.assertNotEquals(null, purchaseId, 'Purchase ID should be returned.');
        
        Item__c updatedLaptop = [SELECT AvailableQuantity__c FROM Item__c WHERE Id = :laptop.Id];
        System.assertEquals(8, updatedLaptop.AvailableQuantity__c, 'Inventory should be reduced by 2.');
    }

    // Test a Failed Checkout (Buying too many)
    @isTest
    static void testProcessCheckoutFail() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c laptop = [SELECT Id, Price__c FROM Item__c WHERE Name = 'Laptop' LIMIT 1];

        // Trying to buy 50 laptops, but we only have 10 in my mock database
        String payload = '[{"itemId":"' + laptop.Id + '", "quantity":50, "unitPrice":' + laptop.Price__c + '}]';

        Test.startTest();
        try {
            ItemPurchaseController.processCheckout(acc.Id, payload);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Not enough quantity'), 'Error message should match.');
        }
        Test.stopTest();
    }
}
@isTest
private class ItemPurchaseControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test TrueSolv Account');
        insert testAccount;

        // Automatically fetch the real dropdown options from your database!
        String realType = Item__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        String realFamily = Item__c.Family__c.getDescribe().getPicklistValues()[0].getValue();

        List<Item__c> items = new List<Item__c>{
            new Item__c(Name = 'Laptop', Description__c = 'Fast PC', Type__c = realType, Family__c = realFamily, Price__c = 1000, AvailableQuantity__c = 10),
            new Item__c(Name = 'Mouse', Description__c = 'Wireless', Type__c = realType, Family__c = realFamily, Price__c = 50, AvailableQuantity__c = 0)
        };
        insert items;

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

    @isTest
    static void testGetItems() {
        // Fetch the same dynamic values so the search perfectly matches the database
        String realType = Item__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        String realFamily = Item__c.Family__c.getDescribe().getPicklistValues()[0].getValue();

        Test.startTest();
        List<Item__c> results = ItemPurchaseController.getItems('Laptop', realFamily, realType);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return exactly 1 in-stock item.');
        System.assertEquals('Laptop', results[0].Name, 'The returned item should be the Laptop.');
    }

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

    @isTest
    static void testProcessCheckoutSuccess() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c laptop = [SELECT Id, Price__c FROM Item__c WHERE Name = 'Laptop' LIMIT 1];

        String payload = '[{"itemId":"' + laptop.Id + '", "quantity":2, "unitPrice":' + laptop.Price__c + '}]';

        Test.startTest();
        Id purchaseId = ItemPurchaseController.processCheckout(acc.Id, payload);
        Test.stopTest();
        
        System.assertNotEquals(null, purchaseId, 'Purchase ID should be returned.');
        
        Item__c updatedLaptop = [SELECT AvailableQuantity__c FROM Item__c WHERE Id = :laptop.Id];
        System.assertEquals(8, updatedLaptop.AvailableQuantity__c, 'Inventory should be reduced by 2.');
    }

    @isTest
    static void testProcessCheckoutFail() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c laptop = [SELECT Id, Price__c FROM Item__c WHERE Name = 'Laptop' LIMIT 1];

        String payload = '[{"itemId":"' + laptop.Id + '", "quantity":50, "unitPrice":' + laptop.Price__c + '}]';

        Test.startTest();
        try {
            ItemPurchaseController.processCheckout(acc.Id, payload);
            System.assert(false, 'An exception should have been thrown.');
        } catch (Exception e) {
            // Simply assert that the correct TYPE of exception was caught!
            System.assert(e.getTypeName() == 'System.AuraHandledException', 'Expected an AuraHandledException to be thrown.');
        }
        Test.stopTest();
    }
}
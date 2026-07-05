public with sharing class ItemPurchaseController {

    // Fetch Items with Filters
    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItems(String searchTerm, String familyFilter, String typeFilter) {
        String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c, AvailableQuantity__c ' +
                       'FROM Item__c WHERE AvailableQuantity__c > 0';

        if (String.isNotBlank(searchTerm)) {
            String likeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            query += ' AND (Name LIKE :likeTerm OR Description__c LIKE :likeTerm)';
        }
        if (String.isNotBlank(familyFilter)) {
            query += ' AND Family__c = :familyFilter';
        }
        if (String.isNotBlank(typeFilter)) {
            query += ' AND Type__c = :typeFilter';
        }

        return Database.query(query);
    }

    // Check if the current user is a Manager
    @AuraEnabled(cacheable=true)
    public static Boolean isUserManager() {
        User currentUser = [SELECT IsManager__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return currentUser.IsManager__c == true;
    }

    // Process the Cart Checkout Transaction
    @AuraEnabled
    public static Id processCheckout(Id accountId, String cartPayload) {
        List<CartWrapper> cartItems = (List<CartWrapper>) JSON.deserialize(cartPayload, List<CartWrapper>.class);
        
        if (cartItems.isEmpty()) {
            throw new AuraHandledException('Cart is empty.');
        }

        // Map to hold Item IDs and the quantity requested
        Map<Id, Decimal> requestedQuantities = new Map<Id, Decimal>();
        for (CartWrapper cartItem : cartItems) {
            requestedQuantities.put(cartItem.itemId, cartItem.quantity);
        }

        // Lock the Item rows for update to prevent race conditions (Concurrency control)
        List<Item__c> itemsToUpdate = [SELECT Id, AvailableQuantity__c, Price__c 
                                       FROM Item__c 
                                       WHERE Id IN :requestedQuantities.keySet() 
                                       FOR UPDATE];

        for (Item__c item : itemsToUpdate) {
            Decimal requested = requestedQuantities.get(item.Id);
            if (item.AvailableQuantity__c < requested) {
                throw new AuraHandledException('Not enough quantity for item: ' + item.Id);
            }
            // Deduct the inventory
            item.AvailableQuantity__c -= requested;
        }

        // Create the Parent Purchase Record
        Purchase__c newPurchase = new Purchase__c(
            Name = 'Purchase - ' + Date.today().format(),
            ClientId__c = accountId
        );
        insert newPurchase;

        // Create the Child Purchase Line Records
        List<PurchaseLine__c> linesToInsert = new List<PurchaseLine__c>();
        for (CartWrapper cartItem : cartItems) {
            PurchaseLine__c line = new PurchaseLine__c(
                PurchaseId__c = newPurchase.Id,
                ItemId__c = cartItem.itemId,
                Amount__c = cartItem.quantity,
                UnitCost__c = cartItem.unitPrice
            );
            linesToInsert.add(line);
        }

        insert linesToInsert;
        update itemsToUpdate;

        return newPurchase.Id;
    }

    @AuraEnabled
    public static Item__c createNewItem(String name, String description, String typeVal, String familyVal, Decimal price, Decimal quantity) {
        if (!isUserManager()) {
            throw new AuraHandledException('Unauthorized: Only managers can create items.');
        }

        String imageUrl = UnsplashService.getItemImageUrl(name);

        Item__c newItem = new Item__c(
            Name = name,
            Description__c = description,
            Type__c = typeVal,
            Family__c = familyVal,
            Price__c = price,
            AvailableQuantity__c = quantity,
            Image__c = imageUrl
        );

        insert newItem;
        return newItem;
    }

    // Wrapper class to match the JSON structure coming from LWC
    public class CartWrapper {
        public Id itemId;
        public Decimal quantity;
        public Decimal unitPrice;
    }
}
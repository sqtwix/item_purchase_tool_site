import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import getItems from '@salesforce/apex/ItemPurchaseController.getItems';
import isUserManager from '@salesforce/apex/ItemPurchaseController.isUserManager';
import processCheckout from '@salesforce/apex/ItemPurchaseController.processCheckout';
import createNewItem from '@salesforce/apex/ItemPurchaseController.createNewItem';

export default class ItemPurchaseTool extends NavigationMixin(LightningElement) {
    // Automatically gets the Account ID from the record page
    @api recordId; 

    // State variables
    @track items = [];
    @track cart = [];
    isManager = false;
    
    // Filters
    searchTerm = '';
    selectedFamily = '';
    selectedType = '';

    // Modal toggles
    showCartModal = false;
    showNewItemModal = false;

    // New Item Form Data
    newItemName = '';
    newItemDesc = '';
    newItemType = '';
    newItemFamily = '';
    newItemPrice = 0;
    newItemQty = 0;

    // Check if user is a manager on load
    @wire(isUserManager)
    wiredManager({ error, data }) {
        if (data) {
            this.isManager = data;
        }
    }

    // Fetch items dynamically based on filters
    @wire(getItems, { searchTerm: '$searchTerm', familyFilter: '$selectedFamily', typeFilter: '$selectedType' })
    wiredItems({ error, data }) {
        if (data) {
            this.items = data;
        } else if (error) {
            this.showToast('Error', 'Failed to load items', 'error');
        }
    }

    get itemCount() {
        return this.items ? this.items.length : 0;
    }

    // Filter Handlers
    handleSearch(event) {
        this.searchTerm = event.target.value;
    }
    handleFamilyChange(event) {
        this.selectedFamily = event.target.value;
    }
    handleTypeChange(event) {
        this.selectedType = event.target.value;
    }

    // Cart Logic
    addToCart(event) {
        const itemId = event.target.dataset.id;
        const selectedItem = this.items.find(item => item.Id === itemId);

        if (selectedItem.AvailableQuantity__c <= 0) {
            this.showToast('Out of Stock', 'This item is currently unavailable.', 'warning');
            return;
        }

        // Check if already in cart
        let cartItem = this.cart.find(c => c.itemId === itemId);
        if (cartItem) {
            if (cartItem.quantity >= selectedItem.AvailableQuantity__c) {
                this.showToast('Limit Reached', 'Cannot add more than available stock.', 'warning');
                return;
            }
            cartItem.quantity += 1;
        } else {
            this.cart.push({
                itemId: selectedItem.Id,
                name: selectedItem.Name,
                quantity: 1,
                unitPrice: selectedItem.Price__c
            });
        }
        
        this.cart = [...this.cart]; 
        this.showToast('Success', `${selectedItem.Name} added to cart!`, 'success');
    }

    openCart() { this.showCartModal = true; }
    closeCart() { this.showCartModal = false; }

    // Checkout Process
    handleCheckout() {
        if (this.cart.length === 0) {
            this.showToast('Error', 'Your cart is empty.', 'error');
            return;
        }

        const payload = JSON.stringify(this.cart);

        processCheckout({ accountId: this.recordId, cartPayload: payload })
            .then((purchaseId) => {
                this.showToast('Success!', 'Order placed successfully.', 'success');
                this.cart = [];
                this.closeCart();
                
                // Navigate to the newly created Purchase record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: purchaseId,
                        objectApiName: 'Purchase__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.showToast('Checkout Failed', error.body.message, 'error');
            });
    }

    // New Item Modal Logic
    openNewItemModal() { this.showNewItemModal = true; }
    closeNewItemModal() { this.showNewItemModal = false; }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleCreateItem() {
        createNewItem({
            name: this.newItemName,
            description: this.newItemDesc,
            typeVal: this.newItemType,
            familyVal: this.newItemFamily,
            price: this.newItemPrice,
            quantity: this.newItemQty
        })
        .then(() => {
            this.showToast('Success', 'New item created successfully! Image is generating in background.', 'success');
            this.closeNewItemModal();
            // Force a refresh of the wire adapter by slightly modifying the search term
            this.searchTerm = this.searchTerm + ' '; 
        })
        .catch(error => {
            this.showToast('Error', 'Failed to create item.', 'error');
        });
    }

    // Notification 
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
import React, { createContext, useState, useContext, useEffect } from 'react';

const CartContext = createContext();

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
};

export const CartProvider = ({ children }) => {
  const [cartItems, setCartItems] = useState([]);
  const MAX_CART_ITEMS = 20;
  const MAX_ITEM_QUANTITY = 4;

  // Загружаем корзину из localStorage при монтировании
  useEffect(() => {
    const savedCart = localStorage.getItem('cart');
    if (savedCart) {
      setCartItems(JSON.parse(savedCart));
    }
  }, []);

  // Сохраняем корзину в localStorage при изменении
  useEffect(() => {
    localStorage.setItem('cart', JSON.stringify(cartItems));
  }, [cartItems]);

  const addToCart = (card, quality = 'NM', quantity = 1) => {
    setCartItems(prevItems => {
      // Проверяем общий лимит корзины
      const totalItems = prevItems.reduce((sum, item) => sum + item.quantity, 0);
      if (totalItems + quantity > MAX_CART_ITEMS) {
        alert(`Максимальное количество карт в корзине - ${MAX_CART_ITEMS}`);
        return prevItems;
      }

      // Ищем такую же карту с таким же качеством
      const existingItemIndex = prevItems.findIndex(
        item => item.card.id === card.id && item.quality === quality
      );

      if (existingItemIndex >= 0) {
        // Проверяем лимит для конкретной карты
        const existingQuantity = prevItems[existingItemIndex].quantity;
        if (existingQuantity + quantity > MAX_ITEM_QUANTITY) {
          alert(`Максимальное количество для этой карты - ${MAX_ITEM_QUANTITY} шт.`);
          return prevItems;
        }

        // Обновляем количество существующей карты
        const updatedItems = [...prevItems];
        updatedItems[existingItemIndex].quantity += quantity;
        return updatedItems;
      } else {
        // Проверяем лимит для новой карты
        if (quantity > MAX_ITEM_QUANTITY) {
          alert(`Максимальное количество для одной карты - ${MAX_ITEM_QUANTITY} шт.`);
          return prevItems;
        }

        // Добавляем новую карту
        return [...prevItems, {
          card,
          quality,
          quantity,
          addedAt: new Date().toISOString()
        }];
      }
    });
  };

  const removeFromCart = (cardId, quality) => {
    setCartItems(prevItems => 
      prevItems.filter(item => !(item.card.id === cardId && item.quality === quality))
    );
  };

  const updateQuantity = (cardId, quality, newQuantity) => {
    if (newQuantity < 1) return;

    setCartItems(prevItems => {
      // Проверяем общий лимит корзины
      const totalOtherItems = prevItems
        .filter(item => !(item.card.id === cardId && item.quality === quality))
        .reduce((sum, item) => sum + item.quantity, 0);

      if (totalOtherItems + newQuantity > MAX_CART_ITEMS) {
        alert(`Максимальное количество карт в корзине - ${MAX_CART_ITEMS}`);
        return prevItems;
      }

      // Проверяем лимит для конкретной карты
      if (newQuantity > MAX_ITEM_QUANTITY) {
        alert(`Максимальное количество для одной карты - ${MAX_ITEM_QUANTITY} шт.`);
        return prevItems;
      }

      return prevItems.map(item =>
        item.card.id === cardId && item.quality === quality
          ? { ...item, quantity: newQuantity }
          : item
      );
    });
  };

  const clearCart = () => {
    setCartItems([]);
  };

  const getCartTotal = () => {
    return cartItems.reduce((total, item) => total + (item.quantity * (item.card.minPrice || 0)), 0);
  };

  const getCartCount = () => {
    return cartItems.reduce((sum, item) => sum + item.quantity, 0);
  };

   const getPurchaseItems = () => {
    return cartItems.filter(item => !item.card.isPreorder);
  };

  const getPreorderItems = () => {
    return cartItems.filter(item => item.card.isPreorder);
  };

  const getPurchaseTotal = () => {
    return getPurchaseItems().reduce((total, item) => total + (item.quantity * (item.card.minPrice || 0)), 0);
  };

  const getPreorderTotal = () => {
    return getPreorderItems().reduce((total, item) => total + (item.quantity * (item.card.minPrice || 0)), 0);
  };

  const getPurchaseCount = () => {
    return getPurchaseItems().reduce((sum, item) => sum + item.quantity, 0);
  };

  const getPreorderCount = () => {
    return getPreorderItems().reduce((sum, item) => sum + item.quantity, 0);
  };

  const value = {
    cartItems,
    addToCart,
    removeFromCart,
    updateQuantity,
    clearCart,
    getCartTotal,
    getCartCount,
    getPurchaseItems,
    getPreorderItems,
    getPurchaseTotal,
    getPreorderTotal,
    getPurchaseCount,
    getPreorderCount,
    maxCartItems: MAX_CART_ITEMS,
    maxItemQuantity: MAX_ITEM_QUANTITY
  };

  return (
    <CartContext.Provider value={value}>
      {children}
    </CartContext.Provider>
  );
};
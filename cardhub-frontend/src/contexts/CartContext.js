import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';

const CartContext = createContext();
const MAX_CART_ITEMS = 20;
const MAX_ITEM_QUANTITY = 4;

export const useCart = () => {
  const value = useContext(CartContext);
  if (!value) throw new Error('useCart must be used within a CartProvider');
  return value;
};

export const CartProvider = ({ children }) => {
  const [cartItems, setCartItems] = useState(() => {
    try { return JSON.parse(localStorage.getItem('cart') || '[]'); } catch { return []; }
  });

  useEffect(() => localStorage.setItem('cart', JSON.stringify(cartItems)), [cartItems]);

  const addToCart = (card, quality = 'NM', quantity = 1, orderType = card.isPreorder ? 'reservation' : 'purchase') => {
    setCartItems((items) => {
      const count = items.reduce((sum, item) => sum + item.quantity, 0);
      if (count + quantity > MAX_CART_ITEMS) return items;
      const index = items.findIndex((item) => item.card.id === card.id && item.quality === quality && item.orderType === orderType);
      if (index >= 0) {
        const nextQuantity = Math.min(MAX_ITEM_QUANTITY, items[index].quantity + quantity);
        return items.map((item, itemIndex) => itemIndex === index ? { ...item, quantity: nextQuantity } : item);
      }
      return [...items, { card, quality, quantity: Math.min(quantity, MAX_ITEM_QUANTITY), orderType, addedAt: new Date().toISOString() }];
    });
  };

  const removeFromCart = (cardId, quality, orderType) => setCartItems((items) =>
    items.filter((item) => !(item.card.id === cardId && item.quality === quality && item.orderType === orderType))
  );

  const updateQuantity = (cardId, quality, orderType, quantity) => setCartItems((items) =>
    items.map((item) => item.card.id === cardId && item.quality === quality && item.orderType === orderType
      ? { ...item, quantity: Math.max(1, Math.min(MAX_ITEM_QUANTITY, quantity)) }
      : item)
  );

  const value = useMemo(() => {
    const getItemsByType = (type) => cartItems.filter((item) => item.orderType === type);
    const totalFor = (items) => items.reduce((sum, item) => sum + Number(item.card.minPrice || 0) * item.quantity, 0);
    return {
      cartItems,
      addToCart,
      removeFromCart,
      updateQuantity,
      clearCart: () => setCartItems([]),
      getCartCount: () => cartItems.reduce((sum, item) => sum + item.quantity, 0),
      getCartTotal: () => totalFor(cartItems),
      getItemsByType,
      getPurchaseItems: () => getItemsByType('purchase'),
      getPreorderItems: () => getItemsByType('reservation'),
      getPurchaseTotal: () => totalFor(getItemsByType('purchase')),
      getPreorderTotal: () => totalFor(getItemsByType('reservation')),
      getPurchaseCount: () => getItemsByType('purchase').reduce((sum, item) => sum + item.quantity, 0),
      getPreorderCount: () => getItemsByType('reservation').reduce((sum, item) => sum + item.quantity, 0),
      maxCartItems: MAX_CART_ITEMS,
      maxItemQuantity: MAX_ITEM_QUANTITY,
    };
  }, [cartItems]);

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
};

import React from 'react';
import { Badge, IconButton } from '@mui/material';
import { ShoppingCart } from '@mui/icons-material';
import { useCart } from '../../contexts/CartContext';

const CartIcon = () => {
  const { getCartCount } = useCart();
  const cartCount = getCartCount();

  return (
    <IconButton color="inherit">
      <Badge badgeContent={cartCount} color="secondary">
        <ShoppingCart />
      </Badge>
    </IconButton>
  );
};

export default CartIcon;
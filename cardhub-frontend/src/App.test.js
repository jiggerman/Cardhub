import { render, screen } from '@testing-library/react';
import App from './App';

test('renders the redesigned CardHub home page', () => {
  render(<App />);
  expect(screen.getByRole('heading', { name: /найдите ту самую карту/i })).toBeInTheDocument();
  expect(screen.getByRole('search')).toBeInTheDocument();
});

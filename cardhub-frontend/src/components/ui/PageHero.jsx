import React from 'react';

const PageHero = ({ eyebrow, title, description, children }) => (
  <section className="page-hero">
    <div className="page-hero__glow" />
    <div className="container page-hero__inner">
      {eyebrow && <span className="eyebrow">{eyebrow}</span>}
      <h1>{title}</h1>
      {description && <p>{description}</p>}
      {children}
    </div>
  </section>
);

export default PageHero;

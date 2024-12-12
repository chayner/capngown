// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
console.log("Debugging application.js");

// Import Turbo from @hotwired/turbo-rails
import { Turbo } from "@hotwired/turbo-rails";

// Stimulus setup
import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Pancake Menu Toggle
document.addEventListener("DOMContentLoaded", function () {
  const menuToggle = document.querySelector(".menu-toggle");
  const menu = document.querySelector(".menu");

  if (menuToggle && menu) {
    menuToggle.addEventListener("click", function () {
      console.log("Menu toggle clicked");
      menu.classList.toggle("active");
    });
  }
});
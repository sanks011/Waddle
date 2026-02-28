# 🐧 Waddle

> **Walk outside. Build a kingdom. Be the boss.**

---

## 🤔 What is this?

Waddle is a **fitness app** that turns your daily walks into a game.

- 🚶 **You walk** → your kingdom grows
- 🏰 **You run** → you earn rewards  
- 🛡️ **You stop** → your territory gets weaker

It's like a video game. But the controller is **your legs**.

---

## 👀 What's in this project?

This is the **website** for the Waddle app.

It's the page people see before they download the app.

```
🦸 Hero Section      → the big cool intro screen
✨ Features Section  → shows what the app can do
🦶 Footer            → links and stuff at the bottom
```

---

## 🛠️ How to run it on your computer

### Step 1 — Get the stuff you need
```bash
npm install
```
*(This downloads all the lego pieces the project needs)*

### Step 2 — Start it up
```bash
npm run dev
```
*(This turns it on)*

### Step 3 — Open your browser and go to:
```
http://localhost:3000
```

That's it. You're done! 🎉

---

## 📦 Cool things used to build this

| Thing | What it does |
|-------|-------------|
| **Next.js** | The main framework. Like the skeleton. |
| **Tailwind CSS** | Makes things look pretty. Fast. |
| **Framer Motion** | Makes things move and animate. |
| **Lenis** | Makes scrolling super smooth. |
| **Confetti 🎊** | Shoots confetti when you click stuff. |
| **styled-components** | More style powers. |

---

## 📁 Where is everything?

```
app/              → main pages live here
components/
  hero/           → the top part of the page
  sections/       → features, footer, etc.
  ui/             → small reusable pieces
public/           → images and icons
```

---

## ✏️ Want to change something?

| I want to change... | Edit this file |
|--------------------|---------------|
| The big hero text | `components/hero/hero-section.tsx` |
| The navbar | `components/hero/navbar.tsx` |
| The download button | `components/ui/download-button.tsx` |
| The features cards | `components/sections/features-section.tsx` |
| The footer | `components/sections/footer.tsx` |
| Global styles | `app/globals.css` |

---

## 🎨 Brand Colors

| Color | Hex | Used for |
|-------|-----|---------|
| 🟢 Lime | `#96cc00` | Buttons, highlights |
| 🌲 Dark Forest | `#1e4002` | Text, backgrounds |
| ⚫ Black | `#000000` | Hero background |
| ⚪ White | `#ffffff` | Cards, clean sections |

---

## 🚀 Deploy it live

```bash
npm run build
```

Then push to **Vercel** or **Netlify**. They do the rest automatically.

---

## 🐧 That's it!

If you broke something → press `Ctrl + Z` a bunch of times.

If it still broke → ask for help. No shame. We all do it.

**Happy building! 🏰**

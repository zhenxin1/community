<script setup>
import PetIllustration from '../components/PetIllustration.vue'
</script>

<template>
  <main class="auth-shell">
    <section class="auth-story" aria-label="欢迎来到爪爪社区">
      <div class="story-top"><span class="eyebrow"><span class="tiny-dot"></span> EVERY PAW HAS A STORY</span><span class="story-number">01 / 陪伴的开始</span></div>
      <h1>从一句你好，<br>到一生<span class="serif-accent">陪伴。</span></h1>
      <p class="story-description">记录与毛孩子的小日常，<br>也为每一份温柔，找到新的归处。</p>
      <PetIllustration />
      <div class="story-bottom"><span class="story-note">小小的爪印，大大的世界。</span><span class="story-mini-paws">✦</span></div>
    </section>
    <section class="auth-panel"><slot /></section>
  </main>
</template>

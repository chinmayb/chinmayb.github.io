---
layout: default
---

<div class="home">
  <h2>Latest Posts</h2>
  {% for post in site.posts %}
  <div class="post-preview">
    <h3><a href="{{ post.url }}">{{ post.title }}</a></h3>
    <p>{{ post.excerpt | strip_html | truncate: 150 }}</p>
    <small>{{ post.date | date: "%B %d, %Y" }}</small>
  </div>
  {% endfor %}

</div>

---
layout: post
title:  Creating Jekyll Category Pages on GitHub
date: 2020-03-11
summary: |
 This post looks at how to create simple Category pages using Jekyll that will
 work on GitHub Pages.
tags: jekyll oss
categories:
  - Tech Tips
---
In this Post we'll look at how to create some simple Category pages using Jekyll
on GitHub Pages with GitHub's default set of plugins.  GitHub Pages supports a
[limited subset of Jekyll plugins](https://pages.github.com/versions/) and
unfortunately this list doesn't contain plugins like jekyll-category-pages or
jekyll-archives which would make building category pages easier.  We can,
however, get category pages on GitHub with just a little added effort so keep
reading.

## Solution

Jekyll is a simple and powerful static site generator but it does lack some
features that are standard on blogging platforms like Wordpress.  One of those
lacking features is Category and Tag pages that allow readers to easily navigate
by subject.  I recently started consolidating another blog of mine with this one
and realized I needed topic/category navigation.  I was disappointed to find
that GitHub Pages, which hosts this blog, didn't support categories but with a
bit of digging it was easy enough to get some basic category pages up and
running.

### Create a Layout
To setup some basic categories I started by creating a new layout in the __\_layouts__ 
directory in a file called __category.html__ based off the default template.

{%raw%}
```html
---
layout: default
---

<div class="categories">
    <h1 class="h1 category-title">
      Topic:&nbsp;{{ page.category-name }}/
    </h1>
    <div class="posts">
      {% for post in site.categories[page.category-name] %}
        <div class="post py3">
          <p class="post-meta">
        {% if site.date_format %}
            {{ post.date | date: site.date_format }}
        {% else %}
            {{ post.date | date: "%b %-d, %Y" }}
        {% endif %}
        </p>
          <a href="{{ post.url | relative_url }}" class="post-link">
            <h3 class="h1 post-title">
              {{ post.title }}
            </h3>
          </a>
          <span class="post-summary">
              {{ post.excerpt }}
          </span>
        </div>
      
    </div>
</div>
```
{%endraw%}

You'll notice in this template that I'm using the __site__ and __page__
variables to construct the page. site.categories[] is the list of posts
in specific categories and I'm using the page variable and a custom Front Matter
variable called __category-name__ to access the posts for a specific category.

## Category Pages
Now that we have our category layout template we can construct pages for each
category.  For each category you'll use on your site you'll need to create a new
category page that defines some Front Matter to connect a category to the
template above.  For instance, I have a category called "Azure" so I'll need to
create a file called azure.html with the following content

{%raw%}
```html
---
layout: category
category-name: Azure
permalink: "/category/azure"
---
```
{%endraw%}

And that's all that you'll need in each of your category pages.  The category.html layout
will use the __category-name__ defined in the front matter to build each category
page.

### Category List Page
Once you have your category pages created you'll need an easy way to navigate to
each category.  I used the following in my sidebar to list all the categories on
my site.  

{%raw%}
```html
<input type="checkbox" class="sidebar-checkbox" id="sidebar-checkbox">

<div class="sidebar" id="sidebar">
  <nav class="sidebar-nav">
   <h3 class="category-topic">Topics/</h3>
    {% assign sortedCategories = site.categories | sort %}
    {% for category in sortedCategories %}
     {% assign cat4url = category[0] | remove:' ' | downcase %}
     <a class="sidebar-nav-item" href="{{site.baseurl}}/category/{{cat4url}}">
        {{category[0]}}
     </a>
    {% endfor %}
  </nav>

</div>
```
{%endraw%}

__NOTE:__ Notice that I remove spaces and lowercase the categories in the
template above. This is a pretty important point. The categories that are used
in your posts will need to match the __category-name__ you use in your category
pages' Front Matter for all this to work correctly.  You also need to ensure
that the __permalink__ matches as well.

## Summary
Here is an example of a post Front Matter used on this site.  

{%raw%}
```html
---
layout: post
title:  IO Performance in Azure Explained
date: 2019-12-20
summary: |
 This post looks at IO in Azure using Linux VMs for some
 benchmarking and helps explain what Max IOPS and Max Throughput 
 mean.
tags: azure storage io
categories:
  - Azure
  - Tech Tips
---
```
{%endraw%}
Notice that I have defined two categories for this post, __Azure__ and __Tech
Tips__. As long as I have two category pages defined with the correct Front
Matter this post will display under each of those category pages.

The category page for Azure is listed above and called __azure.html__ in my jekyll
site.  For Tech Tips I use a file called __technology.html__ that contains the
following Front Matter.  

{%raw%}
```html
---
layout: category 
category-name: Tech Tips 
permalink: "/category/techtips"
---
```
{%endraw%}

Note that the permalink address must match the characters in the category-name.
Remember from above we take the category-name and remove any spaces and then
lowercase it when we contstruct the link to our category pages.



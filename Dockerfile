FROM debian
WORKDIR /j-dir
RUN apt-get update
RUN apt-get install ruby-full build-essential -y
RUN gem install jekyll jemoji jekyll-paginate rouge jekyll-gist jekyll-sitemap bundler 

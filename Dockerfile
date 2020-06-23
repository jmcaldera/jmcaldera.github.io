FROM jekyll/jekyll:3.8

# VirtualBox GID so we can use the shared folder
ENV VBOX_GID 998

RUN groupmod -g $VBOX_GID jekyll

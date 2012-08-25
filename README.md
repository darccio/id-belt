I'm Dario Utility Belt
======================

> Batman: "The true crimefighter always carries everything he needs in his utility belt, Robin."

This is my personal utility belt, a little repo to store those little scripts that help me to go through my own projects.

## Status
As long as they are published, that means they are tested for my own needs. Anyway, I love to share and I hope they can become full projects or to be useful to somebody. If you use and improve one of them, don't hesitate to ask me to pull your changes! Fork it on Github and go. Please make sure you're kosher with the UNLICENSE file before contributing.

## EMLeaks
Little evil script that provokes a leak of EM::Connection objects (and some others). It features the OrouborosFromOutherSpace class, a reentrant object counter comparator. To reproduce the leaks, siege the EM server with:

    siege -c 1 -r 50 http://127.0.0.1/

I'm able to leak memory in Rubinius (RBX) 2.0.testing and JRuby 1.7.0.preview2 (OpenJDK 1.7.0_05-icedtea) with EM 0.12.10. MRI 1.9.3-p125 does a great work! It doesn't leak and it is predictible (even the number of objects instantiated).

    rvm install rbx-2.0.testing # you should have clang installed!
    rvm use rbx-2.0.testing@emleaks --create
    bundle install
    bundle exec ruby emleaks.rb # They refused to fight in their bundle wasn't present...
   
    rvm install jruby-1.7.0.preview2
    rvm use jruby-1.7.0.preview2@emleaks --create
    bundle install
    ruby emleaks.rb # Siege it till noon!

    rvm install 1.9.3-p125
    rvm use 1.9.3-p125@emleaks --create
    bundle install
    ruby emleaks.rb # Attack!

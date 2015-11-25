# Inkcite

Inkcite is an opinionated workflow for building modern, responsive email.
Like [Middleman] is to static web sites, Inkcite makes it easy for email
developers to keep their code DRY (don’t repeat yourself) and integrate
versioning, testing and minification into their workflow.

* Powerful media query and fluid-hybrid responsive support
* Easy, flexible templates, variables and Helpers
* ERB for dynamic content and easy A/B Testing and Versioning
* Automatic link tagging and tracking
* Instant compatibility testing with [Email on Acid] or [Litmus]
* Automatic [Litmus] Engagement analytics integration
* Email preview distribution lists
* Automatic image optimization using ImageOptim
* Failsafe rules to double-check your work

## Installation

Inkcite is a Ruby gem.  Ruby comes pre-installed on Mac OS X and Linux. If
you’re using Windows, try [RubyInstaller].

```
gem install inkcite
```

## Getting Started

After Inkcite is installed, you will have access to the `inkcite` command.
Create a new Inkcite email at your terminal or command prompt:

```
inkcite init MY_EMAIL
```

This will create a new directory called `MY_EMAIL` and fill it with the source
files for your new email project.  It includes a subdirectory called `images`
where you store all images for your email.

Change directories into your new project and start the preview server:

```
cd MY_EMAIL
inkcite server
```

Inkcite’s preview server gives you a live view of your email as you build it
by modifying the `source.html`, `helpers.tsv`, `source.txt` and `config.yml`
files.  Open your browser to `http://localhost:4567` to see your email as you
build it.  As you make changes, simply refresh your browser to see up-to-date
results.

The `config.yml` file has an extensive set of properties that influence the
HTML code that Inkcite produces plus how it sends preview emails.

During development, you can refer to your command prompt or terminal window to
see important warnings (such as missing images or links).

## Email Previews

When you’re ready to see what your email looks like in an email client,
Inkcite will send previews on demand.  Make sure you have configured the
`smtp` settings in the `config.yml` file so that Inkcite can send email via
your SMTP server.  When you’re ready to send:

``` inkcite preview ```

With no other parameters, this will send a preview version of your email to
the `from` email address you configured.  You can also use the preview command
to send to your email to internal or client distribution lists for review.

## Compatibility Testing

Testing your Inkcite-built emails with [Litmus] is easy.  Make sure you have
configured the `litmus` section of the `config.yml` file.

``` inkcite test ```

The will create a new email test using your default set of email clients and
send a preview version of the email to Litmus for testing.  Subsequent runs of
the test command will update the same test.  Log into your Litmus account to
review the results of the test.

## Production Builds

After you’ve previewed and tested your email, you’re ready to create the
production-ready email files.  From the project directory:

``` inkcite build ```

By default, this will create the production version of your email.  This
includes fully-qualified URLs for images, link tracking and tagging and a host
of other preflight features.

## Learn More

A step-by-step [tutorial] for building a modern, responsive email from start to
finish is available on the Inkceptional blog.

Documentation for Inkcite is generously hosted by the friendly folks at [Readme].
Get started here: https://inkcite.readme.io/

## Bug Reports

Github Issues is used for managing bug reports and feature requests. If you
run into issues, please search the issues and submit new problems:
https://github.com/inkceptional/inkcite/issues

The best way to get quick responses to your issues and swift fixes to your
bugs is to submit detailed bug reports, include test cases and respond to
developer questions in a timely manner.

## License

Copyright (c) 2014-2015 Jeffrey D. Hoffman. MIT Licensed, see [LICENSE] for
details.

[Middleman]: http://middlemanapp.com
[Email On Acid]: http://emailonacid.com
[Litmus]: http://litmus.com
[rubyinstaller]: http://rubyinstaller.org/
[LICENSE]: https://github.com/inkceptional/inkcite/blob/master/LICENSE
[Readme]: https://readme.io
[tutorial]: http://blog.inkceptional.com/build-a-modern-responsive-email-with-inkcite/

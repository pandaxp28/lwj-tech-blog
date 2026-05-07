#!/usr/bin/env ruby
# frozen_string_literal: true

module ZzzzzzGoogleTag
  TAG_ID = 'G-0M0FF4WD3H'

  SNIPPET = <<~HTML.freeze
    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=#{TAG_ID}"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());

      gtag('config', '#{TAG_ID}');
    </script>
  HTML

  def self.inject(html)
    return html if html.include?("googletagmanager.com/gtag/js?id=#{TAG_ID}")
    return html unless html.include?('</head>')

    html.sub('</head>', "#{SNIPPET}</head>")
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)

    original = File.read(path)
    updated = ZzzzzzGoogleTag.inject(original)
    next if updated == original

    File.write(path, updated)
  end
end

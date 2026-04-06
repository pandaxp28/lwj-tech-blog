#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'

module HomepageRebuilder
  SVG = <<~SVG.freeze
    <svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
      <rect width="512" height="512" rx="96" fill="#111827"/>
      <rect x="44" y="44" width="424" height="424" rx="84" fill="#0f172a" stroke="#22c55e" stroke-width="16"/>
      <text x="256" y="308" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="156" font-weight="700" fill="#f8fafc">LWJ</text>
      <circle cx="402" cy="112" r="28" fill="#22c55e"/>
    </svg>
  SVG

  DATA_URI = "data:image/svg+xml,#{CGI.escape(SVG).gsub('+', '%20')}"

  def self.strip_html(text)
    text.to_s.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
  end

  def self.excerpt_for(post)
    text = strip_html(post.data['description'] || post.data['excerpt'] || post.content)
    text.length > 140 ? "#{text[0, 140]}…" : text
  end

  def self.href_for(site, post)
    url = post.url.to_s
    return url if url.start_with?(site.baseurl.to_s)
    "#{site.baseurl}#{url}"
  end

  def self.homepage_path(site)
    base = site.baseurl.to_s.sub(%r{^/}, '')
    base.empty? ? File.join(site.dest, 'index.html') : File.join(site.dest, base, 'index.html')
  end

  def self.render(site)
    posts = site.posts.docs.sort_by { |p| p.date || Time.at(0) }.reverse.first(12)

    cards = posts.map do |post|
      href = href_for(site, post)
      title = CGI.escapeHTML(post.data['title'].to_s)
      excerpt = CGI.escapeHTML(excerpt_for(post))
      date = CGI.escapeHTML(post.date.strftime('%b %-d, %Y'))
      categories = Array(post.data['categories']).join(', ')
      categories_html = CGI.escapeHTML(categories)

      <<~HTML
        <a class="card" href="#{href}">
          <div class="card-title">#{title}</div>
          <div class="card-excerpt">#{excerpt}</div>
          <div class="card-meta">#{date}#{categories.empty? ? '' : "  ·  #{categories_html}"}</div>
        </a>
      HTML
    end.join("\n")

    <<~HTML
      <!doctype html>
      <html lang="ja">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{CGI.escapeHTML(site.config['title'].to_s)}</title>
        <meta name="description" content="#{CGI.escapeHTML(site.config['description'].to_s)}">
        <link rel="icon" type="image/svg+xml" href="#{DATA_URI}">
        <style>
          :root { color-scheme: dark; }
          * { box-sizing: border-box; }
          body { margin: 0; font-family: Arial, Helvetica, sans-serif; background: #0b1220; color: #e5eefc; }
          a { color: inherit; text-decoration: none; }
          .wrap { max-width: 1180px; margin: 0 auto; padding: 28px 22px 40px; }
          .top { display: grid; grid-template-columns: 108px 1fr; gap: 18px; align-items: center; margin-bottom: 22px; }
          .logo { width: 108px; height: 108px; border-radius: 24px; display: block; }
          .site-title { font-size: 30px; font-weight: 700; margin: 0 0 8px; }
          .site-tagline { font-size: 22px; color: #60a5fa; margin: 0 0 6px; }
          .site-desc { color: #b8c4d9; line-height: 1.6; margin: 0; }
          .nav { display: flex; flex-wrap: wrap; gap: 12px; margin: 20px 0 28px; }
          .nav a { padding: 10px 14px; border: 1px solid #23406a; border-radius: 999px; color: #93c5fd; background: rgba(20,30,50,.45); }
          .section-title { font-size: 18px; color: #9fb0cc; margin: 0 0 14px; }
          .cards { display: grid; gap: 18px; }
          .card { display: block; padding: 24px; border: 1px solid rgba(112,133,171,.22); border-radius: 18px; background: rgba(17,24,39,.76); box-shadow: 0 10px 30px rgba(0,0,0,.18); }
          .card:hover { border-color: rgba(96,165,250,.45); transform: translateY(-1px); }
          .card-title { font-size: 24px; font-weight: 700; color: #9cc2ff; margin-bottom: 10px; }
          .card-excerpt { font-size: 16px; line-height: 1.7; color: #d5deeb; margin-bottom: 14px; }
          .card-meta { font-size: 14px; color: #9fb0cc; }
          @media (max-width: 760px) {
            .top { grid-template-columns: 1fr; }
            .logo { width: 88px; height: 88px; }
            .site-title { font-size: 24px; }
            .site-tagline { font-size: 18px; }
            .card-title { font-size: 20px; }
          }
        </style>
      </head>
      <body>
        <div class="wrap">
          <div class="top">
            <img class="logo" src="#{DATA_URI}" alt="LWJ logo">
            <div>
              <h1 class="site-title">#{CGI.escapeHTML(site.config['title'].to_s)}</h1>
              <div class="site-tagline">Windows 保守、GPU 復旧、3D データ活用の技術メモ</div>
              <p class="site-desc">LWJ の技術ブログです。Windows 保守、GPU・Mosaic 復旧、3D データ活用、現場で役立つ小規模ツール開発など、実務で蓄積した技術情報を整理して公開します。</p>
            </div>
          </div>
          <nav class="nav">
            <a href="#{site.baseurl}/">Home</a>
            <a href="#{site.baseurl}/categories/">Categories</a>
            <a href="#{site.baseurl}/tags/">Tags</a>
            <a href="#{site.baseurl}/archives/">Archives</a>
            <a href="#{site.baseurl}/about/">About</a>
          </nav>
          <div class="section-title">最新記事</div>
          <div class="cards">#{cards}</div>
        </div>
      </body>
      </html>
    HTML
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  path = HomepageRebuilder.homepage_path(site)
  next unless File.file?(path)
  File.write(path, HomepageRebuilder.render(site))
end

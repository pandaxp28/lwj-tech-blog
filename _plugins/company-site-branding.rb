#!/usr/bin/env ruby
# frozen_string_literal: true

# Build-time branding overrides for the public site.
# This lets us refine the visible copy without depending on direct edits to
# existing content files through the GitHub connector.

module CompanySiteBranding
  ABOUT_PATHS = [
    '_tabs/about.md',
    '/_tabs/about.md',
    'about.md',
    '/about.md'
  ].freeze

  ABOUT_CONTENT = <<~MARKDOWN
    LWJ の技術ブログです。

    このブログでは、業務の中で蓄積した技術情報や検証結果を、あとから再利用しやすい形で整理して公開しています。

    主なテーマは次の通りです。

    - Windows の保守、回復、運用メモ
    - NVIDIA Mosaic、GPU 表示復旧、TDR 関連の検証
    - 3D データ確認ツールや周辺機能の開発
    - 現場で使えるバッチ、補助ツール、小規模ユーティリティ
    - 実務で役立つ手順書、設定例、トラブル対応記録

    単なる紹介ではなく、実際に手を動かして確認した内容をベースに、再現しやすい情報として残していく方針です。

    最初の記事として、NVIDIA Mosaic 復旧手順と復旧バッチを掲載しています。  
    今後も、Windows、GPU、3D データ活用、運用改善に関する内容を順次追加していきます。
  MARKDOWN

  def self.apply_site_config(site)
    site.config['title'] = 'LWJ Tech Blog'
    site.config['tagline'] = 'Windows 保守、GPU 復旧、3D データ活用の技術メモ'
    site.config['description'] = 'LWJ の技術ブログです。Windows 保守、GPU・Mosaic 復旧、3D データ活用、現場で役立つ小規模ツール開発など、実務で蓄積した技術情報を整理して公開します。'
    social = site.config['social'] || {}
    social['name'] = 'LWJ'
    social['links'] = ['https://github.com/pandaxp28', 'http://www.lwj.co.jp/']
    site.config['social'] = social
  end

  def self.about_page?(doc)
    rel = if doc.respond_to?(:relative_path)
            doc.relative_path.to_s
          elsif doc.respond_to?(:path)
            doc.path.to_s
          else
            ''
          end

    ABOUT_PATHS.any? { |p| rel.end_with?(p) }
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  CompanySiteBranding.apply_site_config(site)
end

[:pages, :documents].each do |scope|
  Jekyll::Hooks.register scope, :pre_render do |doc|
    next unless CompanySiteBranding.about_page?(doc)

    doc.content = CompanySiteBranding::ABOUT_CONTENT
  end
end

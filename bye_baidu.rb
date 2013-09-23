#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'
require 'tempfile'
require 'logger'
require 'json'

TOTAL_PAGE = 100  # Put actual page number here

SPACE_BASE_URL = "http://hi.baidu.com"
SPACE_URL = "http://hi.baidu.com/mvp_xuan/?page=%s"
ARTICLE_PATH = 'article > div[class="mod-realcontent mod-cs-contentblock"] > div[class="item-head"] > a'

POST_TIME = 'div[class="content-head clearfix"] > div[class="content-other-info"] > span'
POST_TITLE = 'div[class="content-head clearfix"] > h2'
POST_CONTENT = 'div[id="content"]'

OUT_PUT_DIR = '/tmp/bye_baidu/' # Change it to wherever have write permission

WAIT_TIME_SHORT = 0.8
WAIT_TIME_LONG = 3


def get_all_link(interval)
  post_collections = []
  interval.each do |n|
    doc = Nokogiri::HTML(open(SPACE_URL % n))
    doc.css(ARTICLE_PATH).each do |a|
      post_collections << a['href']
    end
  end
  post_collections
end


def get_post_detail(url)
  posts = [['title',POST_TITLE],
           ['time',POST_TIME],
           ['content',POST_CONTENT]]
  res = {}
  print '.'
  doc = Nokogiri::HTML(open(url))
  posts.each do |x, y|
    doc.css(y).each do |n|
      res[x] = n.content
    end
  end
  sleep(WAIT_TIME_SHORT)
  res
end


def pre_check
  if File.exist? OUT_PUT_DIR
    puts("Save posts into %s" % OUT_PUT_DIR)
  else
    Dir.mkdir OUT_PUT_DIR
    puts("Save posts into %s" % OUT_PUT_DIR)
  end
end


def write_file(str, name)
  File.open(File.join(OUT_PUT_DIR, name), 'w') {|fp| fp.write(str.to_json)}
end


def main
  pre_check
  final_res = []
  (1..TOTAL_PAGE).each_slice(5) do |s|
    p s
    get_all_link(s).each do |url|
      final_res << get_post_detail(File.join(SPACE_BASE_URL, url))
    end

    write_file(final_res, "%s_%s.json" % [s[0], s[-1]])
    final_res.clear
    p "Done"
    sleep(WAIT_TIME_LONG)
  end
end


if __FILE__ == $0
  main
end

#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'
require 'tempfile'
require 'logger'
require 'json'


USER_NAME = ''

PAGE_COUNT = 100    # Put actual page number here

SPACE_BASE_URL = "http://hi.baidu.com"
SPACE_URL = "http://hi.baidu.com/#{USER_NAME}/?page=%s"

ARTICLE_PATH = 'article > div[class="mod-realcontent mod-cs-contentblock"] > div[class="item-head"] > a'
POST_TIME = 'div[class="content-head clearfix"] > div[class="content-other-info"] > span'
POST_TITLE = 'div[class="content-head clearfix"] > h2'
POST_CONTENT = 'div[id="content"]'

OUT_PUT_DIR = '/tmp/bye_baidu/'   # Change it to wherever have write permission

WAIT_TIME_SHORT = 0.8
WAIT_TIME_LONG = 3

LOG_LEVEL = Logger::DEBUG

START_PAGE = 1   # Change this to 10 and PAGE_COUNT, then page 10 to 100 will be fetched, page 1 to 9 will be ignored.
END_PAGE = nil   # TODO  if this value is not nil, then PAGE_COUNT will be overwritten by this value,
                 # TODO  page [START_PAGE]..[END_PAGE] will be fetched.

PAGE_SLICE = 5   # Will fetch 5 page one time and save to a file

READ_PAGE_TIMEOUT = 10

RETRY_COUNT = 1  # TODO  if fetch page timeout how many times retry it

# ----------------------------------------------------------------------------------------------------------------------

def make_logger
  log = Logger.new(STDOUT)
  log.level = LOG_LEVEL
  log
end

$log = make_logger

def get_all_link(interval)
  post_collections = []
  timeout_list = []
  interval.each do |n|
    begin
      doc = Nokogiri::HTML(open(SPACE_URL % n))
      doc.css(ARTICLE_PATH).each do |a|
        post_collections << a['href']
      end
      sleep(WAIT_TIME_SHORT)
    rescue Timeout::TimeoutError
      $log.error("Time out when fetch #{SPACE_URL % n}, this one will skipped for now and retry after all done")
      timeout_list << SPACE_URL % n
    end
  end
  if timeout_list.empty?
    post_collections
  else
    [post_collections, timeout_list]
  end
end


def get_post_detail(url)
  timeout_list = []
  posts = [['title',POST_TITLE],
           ['time',POST_TIME],
           ['content',POST_CONTENT]]
  res = {}
  begin
    doc = Nokogiri::HTML(open(url))
    posts.each do |x, y|
      doc.css(y).each do |n|
        res[x] = n.content
      end
    end
    print '.'
    sleep(WAIT_TIME_SHORT)
  rescue Timeout::TimeoutError
    $log.error("Time out when fetch #{url}, this one will skipped for now and retry after all done")
    timeout_list << url
  end
  res
end


def pre_check
  if File.exist? OUT_PUT_DIR
    $log.info("Exported data will be saved into #{OUT_PUT_DIR}")
  else
    $log.info('Create output dir')
    Dir.mkdir OUT_PUT_DIR
    $log.info("Exported data will be saved into #{OUT_PUT_DIR}")
  end
end


def write_file(str, name)
  File.open(File.join(OUT_PUT_DIR, name), 'w') {|fp| fp.write(str.to_json)}
end


def main
  pre_check
  final_res = []
  (START_PAGE..PAGE_COUNT).each_slice(PAGE_SLICE) do |s|
    $log.info("Parsing page#{s[0]}-#{s[-1]}")
    get_all_link(s).each do |url|
      final_res << get_post_detail(File.join(SPACE_BASE_URL, url))
    end

    write_file(final_res, "%s_%s.json" % [s[0], s[-1]])
    final_res.clear
    $log.info("Done")
    sleep(WAIT_TIME_LONG)
  end
end


if __FILE__ == $0
  pre_check
end

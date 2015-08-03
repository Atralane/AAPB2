require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class Exhibit < Cmless
  ROOT = (Rails.root + 'app/views/exhibits').to_s
  
  attr_reader :summary_html
  attr_reader :author_html
  attr_reader :main_html
  attr_reader :links_html
  
  attr_reader :head_html
  
  def self.all_top_level
    @all_top_level ||=
      Exhibit.select { |exhibit| !exhibit.path.match(/\//) }
  end
  
  def self.exhibits_by_item_id
    @exhibits_by_item_id ||=
      Hash[
        Exhibit.map{ |exhibit| exhibit.ids }.flatten.uniq.map do |id|
          [
            id, 
            Exhibit.select { |exhibit| exhibit.ids.include?(id) }
          ]
        end
      ]
  end
  
  def self.find_by_item_id(id)
    self.exhibits_by_item_id[id] || []
  end
    
  def facets
    @facets ||= Solr.instance.connect.select(params: {
        q: "exhibits:#{path}", 
        rows: 0, 
        facet: true, 
        'facet.field' => ['genres', 'topics']
      })['facet_counts']['facet_fields']
  end
    
  def thumbnail_url
    @thumbnail_url ||=
      Nokogiri::HTML(head_html).xpath('//img[1]/@src').first.text
  end
  
  def ids
    items.keys
  end
  
  def items
    # TODO: Add the items of the children.
    @items ||= begin
      doc = Nokogiri::HTML(main_html)
      Hash[
        doc.xpath('//a').select { |el| 
          el.attribute('href').to_s.match('^/catalog/.+')
        }.map { |el| 
          [
            el.attribute('href').to_s.gsub('/catalog/', ''),
            (el.attribute('title').text rescue el.text)
          ]
        }
      ]
    end
  end
  
  def formatted
    @formatted ||= begin
      left = false
      @main_html.gsub('<img ') do |match|
        left = !left
        "<img class='pull-#{left ? 'left' : 'right'}' "
      end
    end
  end
  
  def links
    @links ||=
      Nokogiri::HTML(links_html).xpath('//a').map { |el| 
        [
          el.text,
          el.attribute('href').to_s
        ]
      }
  end  
    
end
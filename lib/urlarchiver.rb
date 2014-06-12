require 'nokogiri'
require 'pdfkit'
require 'open-uri'
require 'fileutils'
require 'json'

class URLArchiver
  def initialize(type)
    @type = type
    @output
  end

  # Archive a single url
  def archiveone(url)
    begin
      html = Nokogiri::HTML(open(url))
      url.gsub!("https", "http")
      k = PDFKit.new(url, :page_size => "Letter")
      pdf = k.to_pdf

      # Save files
      FileUtils::mkdir_p 'public/uploads/archive'
      filepath = "public/uploads/archive/"+url.gsub("http", "https").gsub("/", "").gsub(".", "").gsub(":", "")+".pdf"
      File.open(filepath.gsub(".pdf", ".html"), 'w') { |file| file.write(html) }
      file = k.to_file(filepath)
    
      # Save output if single url
      if @type == "single"
        @output = Hash.new
        @output[:pdf_path] = filepath
        @output[:html_path] = filepath.gsub(".pdf", ".html")
        @output[:text] = html.text
      end

      # Return file paths
      out = Hash.new
      out[:pdf_path] = filepath
      out[:html_path] = filepath.gsub(".pdf", ".html")
      
      if @type == "multifull"
        out[:text] = html.text
      end
      return out
    rescue
    end
  end

  # Archive multiple fields in a json
  def multiarchive(json, field)
    pjson = JSON.parse(json)
    htmlfield = field+"_htmlpath"
    pdffield = field+"_pdfpath"
    @output = Array.new

    pjson.each do |p|
      pitem = Hash.new
      paths = archiveone(p[field])

      # Save paths
      if !(paths == nil)
        pitem[htmlfield] = paths[:pdf_path]
        pitem[pdffield] = paths[:html_path]
      end
      
      # Save other fields
      p.each do |key, value|
        pitem[key] = value
      end

      @output.to_a
      @output.push(pitem)
    end
  end
  
  # Generate JSON from output
  def genOutput
    return JSON.pretty_generate(@output)
  end
end

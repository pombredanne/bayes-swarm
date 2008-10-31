require 'date'
require 'erb'

output_file = "/home/battleho/swarm/sources/prototype1/ror/public/monitor.html"

storevalues = `find ~/swarm/pagestore/ -type d -maxdepth 3 | egrep '[0-9]{4}/[0-9]{1,2}/[0-9]{1,2}' | xargs du -s`

# Expected sample values
# storevalues = <<-EOF
# 47160   /home/battleho/swarm/pagestore/2008/9/16
# ...
# 56320   /home/battleho/swarm/pagestore/2008/10/1
# EOF

mysqlvalues = `ls -latr ~/swarm/mysqldump | grep swarm_dump | awk '{print $5 " " $9 }'`

# Expected sample values
# mysqlvalues = <<-EOF
# 113736755 swarm_dump_20081002.sql.gz
# ...
# 132744981 swarm_dump_20081031.sql.gz
# EOF

# Utility method
def xlabels(entries)
  res = []
  se = entries.keys.sort
  res << se.first << se[se.length / 4] << se[se.length * 3 / 4] << se.last
  return res.map { |d| d.strftime('%b, %d')}.join('|')
end

def get_pagestore_entries(values)
  entries = {}
  values.each_line do |line|
    if line =~ /(\d+)\s+.+\/(\d\d\d\d\/\d\d?\/\d\d?)/
      date = Date.strptime($2, '%Y/%m/%d')
      entries[date] = $1.to_i
    end
  end 
  return entries 
end

def get_mysqldump_entries(values)
  entries = {}
  values.each_line do |line|
    if line =~ /(\d+) swarm_dump_(\d\d\d\d)(\d\d)(\d\d)\.sql\.gz/
      date = Date.strptime("#{$2}/#{$3}/#{$4}", '%Y/%m/%d')
      entries[date] = $1.to_i / 1024
    end
  end 
  return entries
end

def integrate_missing_points(entries)
  (entries.keys.min..entries.keys.max).each { |d| entries[d] ||= 0 }
  return entries
end

def generate_template(entries)
  # Create chart string
  s = "http://chart.apis.google.com/chart?"
  s << "cht=lc" # chart type
  s << "&chs=200x100" # chart size
  s << "&chxt=x,y" # chart axes
  s << "&chco=0000ff" # chart color
  s << "&chm=B,aaaaff,0,0,0" # chart area
  s << "&chds=#{entries.values.min},#{entries.values.max}" # chart range
  s << "&chd=t:" << entries.keys.sort.map { |k| entries[k]}.join(",") # chart values
  # s << "&chxl=0:|" << entries.keys.sort.join("|") << "|1:|#{entries.values.min / 1024}|#{entries.values.max / 1024}" # chart labels
  s << "&chxl=0:|#{xlabels(entries)}|1:|#{entries.values.min / 1024}|#{entries.values.max / 1024}" # chart labels

  # Produce output page fragment
  template = %q{
    <table>
      <tr valign="top"><td>
        <img src="<%= s %>" >
      </td><td>    
        <table border="1">
          <tr><th>Date</th><th>Size (Mb)</th></tr>
          <% entries.keys.sort.each do |k| %>
            <tr><td><%= k.strftime('%Y-%m-%d') %></td><td><%= entries[k] / 1024 %></tr>
          <% end %>
        </table>
      </tr></td>
    </table>
  }
  erbpage = ERB.new(template)  
  return erbpage.result(binding)
end

# Parse entries, integrate missing points and generate template
storetemplate = generate_template(integrate_missing_points(get_pagestore_entries(storevalues)))
mysqltemplate = generate_template(integrate_missing_points(get_mysqldump_entries(mysqlvalues)))

template = %q{
  <html>
  <head>
    <style>
      * { font-family: sans-serif; font-size:10px }
    </style>
  </head>
  <body>
  <table>
    <tr><th>Pagestore</th><th>Database Backup</th></tr>
    <tr valign="top">
      <td><%= storetemplate %></td>
      <td><%= mysqltemplate %></td>
    </tr>
  </table>
  <p>Generated on <%= Time.now %></p>
  </body>
  </html>  
}

File.open(output_file, "w") do |f| 
  f.puts ERB.new(template).result
end
#
# rb_main.rb
# mrHost
#
# Created by Shawn Anderson on 11/19/08.
# Copyright Edmunds Inc 2008. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'

# Loading all the Ruby project files.
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.entries(dir_path).each do |path|
    if path != File.basename(__FILE__) and path[-3..-1] == '.rb'
        require(path)
    end
end

def swap_env(sender)
    $host.set_host sender.title
    $item.title = $host.get_current_env
end

$host = Host.new
$host.load_config
$host.load_hosts

app = NSApplication.sharedApplication
icon = NSImage.new.initWithContentsOfFile("#{NSBundle.mainBundle.resourcePath}/utterface_background.png")

bar = NSStatusBar.systemStatusBar()
$item = bar.statusItemWithLength(NSVariableStatusItemLength)

$item.title = $host.get_current_env
#$item.title = "mrHost"
$item.image = icon

menu = NSMenu.new


$host.env_names.each do |env|
	opt = NSMenuItem.new
	opt.title = env
	opt.action = "swap_env:"
	opt.enabled = true
    
	menu.addItem(opt)
end

menu.addItem(NSMenuItem.separatorItem)

opt = NSMenuItem.new
opt.title = "Quit"
opt.action = "terminate:"
opt.enabled = true

menu.addItem(opt)


$item.menu = menu


$item.highlightMode = true

# Starting the Cocoa main loop.
#NSApplicationMain(0, nil)
app.run
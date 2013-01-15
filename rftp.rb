#!/usr/bin/ruby
require 'net/ftp'
class NilClass
  def join(s)
    nil
  end
end

class FtpClient
  
  def initialize(host = nil)
    @binary = true
    @passive = false
    @ftp = nil
    open_remote_connection(host)
    shell
  end
  
  #Open a remote connection. 
  #Ignore the port for now.
  def open_remote_connection(host, port=nil)
    if host == nil
      print "Server: "
      host = STDIN.gets.chomp
      return if host == nil || host == ''
    end
    close_remote_connection #just in case we have an open connection.
    print "User: "
    user = STDIN.gets.chomp
    print "Password: "
    password = STDIN.gets.chomp
    begin
      if user == nil || user == ''
        @ftp = Net::FTP.new(host)
      else
        @ftp = Net::FTP.new(host, user, password)
      end
    rescue => error
      puts "Open failed with error: #{error}"
    end
  end

  #Login as user
  def login(username)
    if username == nil
      print "User: "
      user = STDIN.gets.chomp
      return if user == nil || user == ''
    end
    print "Password: "
    password = STDIN.gets.chomp
    begin
      @ftp.login(user, password)
    rescue => error
      puts "Login failed with error: #{error}"
    end
  end

  def close_remote_connection
    @ftp.close if @ftp != nil
    @ftp = nil
  end

  def remote_directory
    if @ftp != nil
      begin
        puts @ftp.list
      rescue => error
        puts "Directory listing failed: #{error}"
      end
    else
      puts "Not connected"
    end
  end
  
  def change_remote_directory(dir)
    if @ftp != nil
      begin
        @ftp.chdir(dir)
      rescue => error
        puts "Change to Directory #{dir} failed: #{error}"
      end
    else
      puts "Not connected"
    end
  end
  
  def remote_mkdir(directory_name)
    if @ftp != nil
      begin
        @ftp.mkdir(directory_name)
      rescue => error
        puts "Creating Directory #{directory_name}: #{error}"
      end
    else
      puts "Not connected"
    end
  end
  
  def remote_rmdir(directory_name)
    if @ftp != nil
      begin
        @ftp.rmdir(directory_name)
      rescue => error
        puts "Removing Directory #{directory_name}: #{error}"
      end
    else
      puts "Not connected"
    end
  end
  
  def remote_rename(from, to)
    if @ftp != nil
      begin
        @ftp.rename(from, to)
      rescue => error
        puts "Unable to rename #{from}: #{error}"
      end
    else
      puts "Not connected"
    end
  end

  def remote_delete(filename)
    if @ftp != nil
      begin
        @ftp.delete(filename)
      rescue => error
        puts "Unable to delete #{filename}: #{error}"
      end
    else
      puts "Not connected"
    end
  end
  
  def put(local_filename, remote_filename = nil)
    remote_filename = File.basename(local_filename) if remote_filename == nil
    if @ftp != nil
      begin
        t = Time.now
        @ftp.passive = @passive
       # print @passive ? "Passive " : "Active "
        if @ascii
          puts "Ascii text mode"
          @ftp.puttextfile(local_filename, remote_filename)
        else
          puts "Binary mode"
          @ftp.putbinaryfile(local_filename, remote_filename)
        end
        puts "Completed in #{Time.now - t}seconds"
      rescue => error
        puts "Unable to send #{local_filename}: #{error}"
      end
    else
      puts "Not connected"
    end
  end
  
  def get(remote_filename, local_filename = nil)
    local_filename = File.basename(remote_filename) if local_filename == nil
    if @ftp != nil
      begin
        t = Time.now
        @ftp.passive = @passive
        #print @passive ? "Passive " : "Active "
        if @ascii
          puts "Ascii text mode"
          @ftp.gettextfile(remote_filename, local_filename)
        else
          puts "Binary mode"
          @ftp.getbinaryfile(remote_filename, local_filename)
        end
        puts "Completed in #{Time.now - t}seconds"
      rescue => error
        puts "Unable to get #{remote_filename}: #{error}"
      end
    else
      puts "Not connected"
    end
  end
  

  def chdir(dir)
    begin
      Dir.chdir(dir)
    rescue => error
      puts "lcd failed: #{error}"
    end
  end
  
  def mkdir(dir)
    begin
      Dir.mkdir(dir)
    rescue => error
      puts "lmkdir failed: #{error}"
    end
  end
  
  def rmdir(dir)
    begin
      Dir.rmdir(dir)
    rescue => error
      puts "lrmdir failed: #{error}"
    end
  end
  
  def pwd
    puts Dir.pwd
  end
  
  def dir(directory = '.')
    directory = '.' if directory == nil || directory == ''
    if File.directory?(directory) 
      Dir.foreach(directory) do |filename|
        if File.directory?(directory + '/' + filename)
          puts "#{filename}/"
        elsif File.file?(directory + '/' + filename)
          stat = File.stat(directory + '/' + filename)
          printf "%-32s %20d   %s\n", filename, stat.size, stat.mtime.to_s
        else
          printf "%-32s\n", filename
        end
      end
    elsif File.file?(directory)
      stat = File.stat(directory)
      printf "%-32s %20d   %s\n", directory, stat.size, stat.mtime.to_s
    else
      puts "Unknown file or directory '#{directory}'"
    end
  end
  
  def shell
    stop = false
    until stop do
    	print "rftp> "
    	if(line = STDIN.gets) == nil
    	  break
  	  end
    	cmd = line.chomp.split(/ /)
    	case cmd[0]
    	when "open";          open_remote_connection(cmd[1], cmd[2])
    	when "user";          login(cmd[1])
    	when "ascii";         @ascii = true
    	when "binary";        @ascii = false
    	when "passive";       @passive = true
    	when "port","active"; @passive = false
    	when "close";         close_remote_connection
    	when "rename";        remote_rename(cmd[1], cmd[2])
    	when "delete","rm";   remote_delete(cmd[1..-1].join(' '))
    	when "mkdir";         remote_mkdir(cmd[1..-1].join(' '))
    	when "rmdir";         remote_rmdir(cmd[1..-1].join(' '))
    	when "lmkdir","!mkdir"; mkdir(cmd[1..-1].join(' '))
    	when "lrmdir","!rmdir"; rmdir(cmd[1..-1].join(' '))
    	when "dir","ls";      remote_directory
    	when "ldir","lls","!ls"; dir(cmd[1..-1].join(' '))
    	when "cd";            change_remote_directory(cmd[1..-1].join(' '))
    	when "lcd";           chdir(cmd[1..-1].join(' '))
    	when "pwd";           puts "would print name of remote directory"
    	when "lpwd";          pwd
    	when "bye","exit","quit";    stop = true
    	when "get";           get(cmd[1], cmd[2])
    	when "put";           put(cmd[1], cmd[2])
    	when nil; #do nothing
    	when "help", "?"; puts <<-EOF
Commands are:
  open  <hostname>          #Opens a connection to the remote server
  user  <username>          #Login user name on server
  ascii                     #Files are transferred as text
  binary                    #Files are transferred unaltered
  passive                   #Data connection from client to server
  port                      #Data connection made from server to client
  close                     #disconnect from remote server
  rename <from> <to>        #Rename a file on the server
  delete <file>             #Delete a file on the server
  mkdir  <directory>        #create a directory on the server
  rmdir  <directory>        #removes a directory on the server
  lmkdir <directory>        #create a directory on this machine
  lrmdir <directory>        #removes a directory on this machine
  dir  or ls                #List files on remote server
  ldir or lls               #List files on this machine
  cd <directory>            #Change to another directory on the server
  lcd  <directory>          #Change to another directory on this machine
  pwd                       #Servers current directory name
  lpwd                      #Current directory on this machine 
  bye or exit               #terminate programm
  get <sfilename> [<lfile>] #get a file from the server. Optionally specify local filename
  put <lfile> [<sfilename>] #copy a file to the server. Optionally specify server filename
EOF
    	else puts "Unknown command #{cmd[0]}"
    	end
    	
    end
    close_remote_connection
  end
end

FtpClient.new(ARGV[0])


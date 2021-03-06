=begin
Setup script to make things easier for the user of PartProject
=end

def checkout
    puts "Checking out boinc...."
    puts `svn co http://boinc.berkeley.edu/svn/trunk/boinc --force`
    puts "\nChecking out boost...."
    Kernel.exec("svn co http://svn.boost.org/svn/boost/tags/release/Boost_1_45_0/ boost")
end

def update_boinc
    puts "Updating boinc...."
    Kernel.exec("svn update boinc --force")
end

def win_depends
    puts "Checking out the windows dependencies. This may take a LONG time...."
    Kernel.exec("svn co http://boinc.berkeley.edu/svn/trunk/boinc_depends_win_vs2005")
end


def clean_build
    Kernel.exec("boinc/make clean");
end

def int_make
    puts "Running make...."
    output = `make`
    puts "make output:"
    puts output
end

def make
    Dir.chdir "boinc" do
        int_make
    end
end

def main_automake(change=false)

    if (change)
        Dir.chdir "boinc"
    end
    
    lines = IO.readlines("Makefile.am")
            lines.each { |line| 
            
                if (line =~ /\w*SERVER_SUBDIRS = .*?$/)
                    if (!line.include?("partproject"))
                        line.sub!(/\n/," partproject\n")
                    end
                    
                end 
            }
    File.rename("Makefile.am", "Makefile.am.OLD")
    File.open("Makefile.am", "w") {|io|
        io << lines
    }
    

    Dir.chdir "sched" do
        sched_automake
    end
end

def sched_automake(change=false)
    
    if (change)
        Dir.chdir "boinc/sched"
    end
    lines = IO.readlines("Makefile.am")
    lines.each { |line| 
    
        if (line =~ /\w*sched_PROGRAMS = .*?\\\n$/)
            if (!line.include?("partproject_assimilator"))
                line.sub!(/\\/," partproject_assimilator \\\npartproject_work_generator \\")
            end
            
        end
        
        if (line =~ /\w*sample_work_generator_LDADD.*?$/)
            line << "\npartproject_work_generator_SOURCES = partproject_work_generator.cpp"
            line << "\npartproject_work_generator_LDADD = $(SERVERLIBS)\n"
            line << "\npartproject_assimilator_SOURCES = $(ASSIMILATOR_SOURCES) partproject_assimilator.cpp"
            line << "\npartproject_assimilator_LDADD = $(SERVERLIBS) ../../boost/stage/lib/libboost_regex.a"
            line << "\npartproject_assimilator_CXXFLAGS= $(AM_CPP_FLAGS) -I../../boost\n"
        end
    }
    File.rename("Makefile.am", "Makefile.am.OLD")
    File.open("Makefile.am", "w") {|io|
        io << lines
    }
end

def setup_and_make
    
    Dir.chdir "boost" do
        puts "Building Boost -- running bootstrap...."
        puts `./bootstrap.sh --with-libraries=regex`
        
        puts "Building Boost -- running bjam...."
        puts `./bjam`
    end
    
    puts "Now beginning BOINC build...."
    Dir.chdir "boinc" do
    
        puts "Modifying Automake files....\n"
        
        main_automake
        
        puts "Running autosetup...."
        output = `./_autosetup`
        puts "autosetup output:"
        puts output;
        
        
        
        puts "Running configure...."
        output = `./configure --disable-manager --disable-client`
        puts "configure output:"
        puts output
        
        int_make
    end
    
end


case ARGV[0]
    when "checkout"
        checkout
    when "win_depends"
        win_depends
    when "update_boinc"
        update_boinc
    when "make"
        make
    when "setup_and_make"
        setup_and_make
    when "main_automake"
        main_automake(true)
    when "sched_automake"
        sched_automake(true)
    else
        puts <<END_DOC
Usage: setup.rb [ARGUMENT]
Perform operations that will help you use PartProject.

Arguments (if an argument doesn't say it works on Windows, it doesn't):
  checkout          checksout and downloads the prerequisites for
                        PartProject, particuarly BOINC and Boost (works
                        on Windows). NOTE: This does not include the 
                        prerequisites to BOINC! On Linux, you need to 
                        get them separately; on Windows use the argument
                        'win_depends' 
  win_depends       downloads the dependencies for BOINC on Windows 
						(works on Windows).
  setup_and_make    compiles PartProject, BOINC and Boost   
END_DOC
end

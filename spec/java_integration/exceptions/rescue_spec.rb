require File.dirname(__FILE__) + "/../spec_helper"

java_import java.lang.OutOfMemoryError
java_import "java_integration.fixtures.ThrowExceptionInInitializer"
java_import "java_integration.fixtures.ExceptionRunner"

describe "A non-wrapped Java error" do
  it "can be rescued using the Java type" do
    exception = OutOfMemoryError.new
    begin
      raise exception
    rescue OutOfMemoryError => oome
    end

    oome.should == exception
  end

  it "can be rescued using Object" do
    begin
      raise OutOfMemoryError.new
    rescue Object => e
      e.should be_kind_of(OutOfMemoryError)
    end
  end

  it "can be rescued using Exception" do
    exception = OutOfMemoryError.new
    begin
      raise exception
    rescue Exception => e
    end

    e.should == exception
  end

  it "cannot be rescued using StandardError" do
    exception = OutOfMemoryError.new
    lambda do
      begin
        raise exception
      rescue => e
      end
    end.should raise_error(exception)
  end

  it "cannot be rescued inline" do
    obj = Object.new
    def obj.go
      raise OutOfMemoryError.new
    end

    lambda do
      obj.go rescue 'foo'
    end.should raise_error(OutOfMemoryError)
  end
end

describe "A non-wrapped Java exception" do
  it "can be rescued using the Java type" do
    exception = java.lang.NullPointerException.new
    begin
      raise exception
    rescue java.lang.NullPointerException => npe
    end

    npe.should == exception
  end

  it "can be rescued using Object" do
    begin
      raise java.lang.NullPointerException.new
    rescue Object => e
      e.should be_kind_of(java.lang.NullPointerException)
    end
  end

  it "can be rescued using Exception" do
    begin
      raise java.lang.NullPointerException.new
    rescue Exception => e
      e.should be_kind_of(java.lang.NullPointerException)
    end
  end

  it "can be rescued using StandardError" do
    begin
      raise java.lang.NullPointerException.new
    rescue StandardError => e
      e.should be_kind_of(java.lang.NullPointerException)
    end
  end

  it "can be rescued inline" do
    obj = Object.new
    def obj.go
      raise java.lang.NullPointerException.new
    end

    (obj.go rescue 'foo').should == 'foo'
  end

  it "can be rescued dynamically using Module" do
    mod = Module.new
    (class << mod; self; end).instance_eval do
      define_method(:===) { |exception| true }
    end
    begin
      raise java.lang.NullPointerException.new
    rescue mod => e
      e.should be_kind_of(java.lang.NullPointerException)
    end
  end

  it "can be rescued dynamically using Class" do
    cls = Class.new
    (class << cls; self; end).instance_eval do
      define_method(:===) { |exception| true }
    end
    begin
      raise java.lang.NullPointerException.new
    rescue cls => e
      e.should be_kind_of(java.lang.NullPointerException)
    end
  end
end

describe "A Ruby-level exception" do
  it "carries its message along to the Java exception" do
    java_ex = JRuby.runtime.new_runtime_error("error message");
    java_ex.message.should == "(RuntimeError) error message"

    java_ex = JRuby.runtime.new_name_error("error message", "name");
    java_ex.message.should == "(NameError) error message"
  end
end

describe "A native exception wrapped by another" do  
  it "gets the first available message from the causes' chain" do
    begin
      ThrowExceptionInInitializer.new.test
    rescue NativeException => e
      e.message.should =~ /lets cause an init exception$/
    end
  end

  it "can be re-raised" do
    lambda {
      begin
        ThrowExceptionInInitializer.new.test
      rescue NativeException => e
        raise e.exception("re-raised")
      end
    }.should raise_error(NativeException)
  end
end

describe "A Ruby subclass of a Java exception" do
  before :all do
    @ex_class = Class.new(java.lang.RuntimeException)
  end

  it "is rescuable with all Java superclasses" do
    exception = @ex_class.new

    begin
      raise exception
      fail
    rescue java.lang.Throwable
      $!.should == exception
    end

    begin
      raise exception
      fail
    rescue java.lang.Exception
      $!.should == exception
    end

    begin
      raise exception
      fail
    rescue java.lang.RuntimeException
      $!.should == exception
    end
  end

  it "presents its Ruby nature when rescued" do
    exception = @ex_class.new

    begin
      raise exception
      fail
    rescue java.lang.Throwable => t
      t.class.should == @ex_class
      t.should equal(exception)
    end
  end
end

describe "A ruby exception raised through java and back to ruby" do
  it "its class and message is preserved" do
    begin
      ExceptionRunner.new.do_it_now do
        raise "it comes from ruby"
      end
      fail
    rescue RuntimeError => e
      e.message.should == "it comes from ruby"
    end
  end
end

describe "A ruby exception raised through java and back " +
         "to ruby via a different thread" do
  it "its class and message is preserved" do
    begin
      ExceptionRunner.new.do_it_threaded do
        raise "it comes from ruby"
      end
      fail
    rescue RuntimeError => e
      e.message.should == "it comes from ruby"
    end
  end
end


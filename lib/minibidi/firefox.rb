module MiniBiDi
  class Firefox
    def self.launch(&block)
      FirefoxLauncher.new.launch(&block)
    end
  end
end

Pod::Spec.new do |s|
s.name         = "HDCycleScrollView"
s.version      = "1.0.0"
s.summary      = "自动生成轮播图片及菜单"
s.description  = <<-DESC
自动生成轮播图片及菜单.
DESC
s.homepage     = "https://github.com/MalongGuo/HDCycleScrollView"
s.license      = { :type => "MIT"}
s.author             = { "漠" => "linuxc2012@163.com" }
s.platform     = :ios, "8.0"
s.source       = { :git => "https://github.com/MalongGuo/HDCycleScrollView.git", :tag => "#{s.version}" }
s.source_files  = "HDCycleScrollView/Lib/HDCycleScrollView/*.{h,m}"
s.exclude_files = "Classes/Exclude"
s.dependency "SDCycleScrollView", "~> 1.65"
end

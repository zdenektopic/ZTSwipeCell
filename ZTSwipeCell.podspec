Pod::Spec.new do |s|
  s.name     = 'ZTSwipeCell'
  s.version  = '1.0.0'
  s.author   = { 'Zdenek Topic' => 'hello@zdenektopic.cz' }
  s.homepage = 'https://github.com/zdenektopic/ZTSwipeCell'
  s.summary  = 'Clear- and Mailbox-like gesture based swipe/pan table view cell.'
  s.license  = 'MIT'
  s.source   = { :git => 'https://github.com/zdenektopic/ZTSwipeCell.git', :tag => '1.0.0' }
  s.source_files = 'ZTSwipeCell'
  s.platform = :ios
  s.ios.deployment_target = '6.0'
  s.requires_arc = true
end

//
//  MBLoader.swift
//  Pods
//
//  Created by Perry on 16/7/7.
//
//

import Foundation

// MARK: - MBLoader

/**
 加载配置对象
 - mask 指定遮罩视图
 - container 指定显示遮罩视图的视图
 - insets 指定遮罩视图和显示视图的边距
 - id 设置请求编号，如：GET_USER_INFO (注：会根据 id 对并发的请求进行分组，同一个 id 的请求会共用一个 loading)
 */

extension MBLoadDefault : MBLoadable {
    public var loadConfig : MBLoadConfig? {
        return MBLoadConfig(container:container)
    }
}

extension MBLoadNone : MBLoadable {
    public var loadConfig : MBLoadConfig? {
        return nil
    }
}

public class MBLoadNone {
    public init() {}
}

public class MBLoadDefault {
    var container:UIView
    public init(container:UIView) {
        self.container = container
    }
}

extension MBLoadConfig:MBLoadable {
    public var loadConfig : MBLoadConfig? {
        return self
    }
}

public class MBLoadConfig {
    
    var mask:UIView
    var container:UIView
    var insets:UIEdgeInsets
    
    internal var count = 1
    
    var id:String
    
    public init(id:String = "MBLOAD_CONFIG_DEFAULT", mask:UIView = MBLoading.loading(), container:UIView, insets:UIEdgeInsets = UIEdgeInsetsZero) {
        self.mask = mask
        self.container = container
        self.insets = insets
        self.id = id
    }
}

// MARK: - MBLoadable

/**
 满足 MBLoadable 协议的类型可以在进行网络请求时显示加载框
  - 实现 loading() 可以自定义加载
 */
public protocol MBLoadable : class {
    var loadConfig : MBLoadConfig? { get }
}

/**
 黑魔法－使用 runtime 为 extension 增加成员变量
 */

private struct MBLoadableKeys {
    static var loadingKey = "loadingKey"
}

extension MBRequestable {
    private var mbLoadConfig:MBLoadConfig? {
        get {
            return objc_getAssociatedObject(self, &MBLoadableKeys.loadingKey) as? MBLoadConfig
        }
        set(loading) {
            objc_setAssociatedObject(
                self,
                &MBLoadableKeys.loadingKey,
                loading as MBLoadConfig?,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

extension MBRequestable {
    public func showLoad(load:MBLoadable) {
        if let config = load.loadConfig { // 如果有配置则说明需要加载框
            if let mbConfig = mbLoadConfig { // 判断之前是否已经有加载框的配置
                if mbConfig.id == config.id { // 判断 id 是否一致，如果一致，则表示和之前的加载框是同一个
                    mbConfig.count += 1
                } else { // 否则用新的加载框替换旧的加载框
                    removeLoad(mbConfig)
                    addLoad(config)
                }
            } else { // 否则设置初始加载框
                addLoad(config)
            }
        }
    }
    
    public func hideLoad(load:MBLoadable) {
        if let config = load.loadConfig { // 如果有配置则说明需要加载框
            if let mbConfig = mbLoadConfig { // 判断之前是否已经有加载框的配置
                if mbConfig.id == config.id { // 判断 id 是否一致，如果一致，则表示和之前的加载框是同一个
                    mbLoadConfig?.count -= 1
                    if (0 == mbLoadConfig?.count) {
                        removeLoad(mbConfig)
                        mbLoadConfig = nil
                    }
                }
            }
        }
    }
    
    private func addLoad(loadConfig:MBLoadConfig) {
        mbLoadConfig = loadConfig
        if let mbConfig = mbLoadConfig {
            if let scrollView = mbConfig.container as? UIScrollView { // 对 UIScrollView 和 UITableView 做特殊处理
                if let superView = scrollView.superview {
                    superView.addMBSubView(mbConfig.mask, insets: mbConfig.insets)
                    scrollView.setContentOffset(scrollView.contentOffset, animated: false)
                    scrollView.scrollEnabled = false
                }
            } else {
                mbConfig.container.addMBSubView(mbConfig.mask, insets: mbConfig.insets)
            }
        }
    }
    
    private func removeLoad(loadConfig:MBLoadConfig) {
        if let scrollView = loadConfig.container as? UIScrollView {
            scrollView.scrollEnabled = true
        }
        loadConfig.mask.removeFromSuperview()
    }
}


//
//  MarklightTextStorage
//
//  Created by Matteo Gavagnin on 01/01/16.
//  Copyright © 2016 MacTeo. LICENSE for details.
//

import UIKit

/**
    `NSTextStorage` subclass that uses `Marklight` to highlight markdown syntax
    on a `UITextView`.
    In your `UIViewController` subclass keep a strong instance of the this
    `MarklightTextStorage` class.
    ```swift
    let textStorage = MarklightTextStorage()
    ```
 
    Customise the appearance as desired:

    * Dynamic text style.
    * Markdown syntax color.
    * Code's font and color.
    * Quotes' font and color.
 
    As per Apple's documentation it should be enough to assign the
    `UITextView`'s `NSLayoutManager` to the `NSTextStorage` subclass, in our
    case `MarklightTextStorage`.
 
    ```swift
     textStorage.addLayoutManager(textView.layoutManager)
    ```
    However I'm experiencing some crashes if I want to preload some text instead
    of letting the user start from scratch with a new text. A workaround is 
    proposed below.
    
    For simplicity we assume you have a `String` to be highlighted inside an
    editable `UITextView` loaded from a storyboard.

    ```swift
    let string = "# My awesome markdown string"
    ```

    Convert `string` to an `NSAttributedString`

    ```swift
    let attributedString = NSAttributedString(string: string)
    ```
 
    Set the loaded string to the `UITextView`

    ```swift
    textView.attributedText = attributedString
    ```
 
    Append the loaded string to the `NSTextStorage`

    ```swift
    textStorage.appendAttributedString(attributedString)
    ```
 
    For more informations on how to implement your own `NSTextStorage` subclass,
    follow Apple's official documentation.
 
    - see: [`NSTextStorage`](xcdoc://?url=developer.apple.com/library/ios/documentation/UIKit/Reference/NSTextStorageDelegate_Protocol_TextKit/index.html#//apple_ref/swift/intf/c:objc(pl)NSTextStorage)
    - see: `Marklight`
 */

open class MarklightTextStorage: NSTextStorage {

    // We store here the `NSAttributedString`.
    fileprivate var imp = NSMutableAttributedString(string: "")
    
    // MARK: Syntax highlight customisation
    
    /**
    `UIColor` used to highlight markdown syntax. Default value is light grey.
    */
    open var syntaxColor = UIColor.lightGray
    
    /**
     Font used for blocks and inline code. Default value is *Menlo*.
     */
    open var codeFontName = "Menlo"
    
    /**
     `UIColor` used for blocks and inline code. Default value is dark grey.
     */
    open var codeColor = UIColor.darkGray
    
    /**
     Font used for quote blocks. Default value is *Menlo*.
     */
    open var quoteFontName = "Menlo"
    
    /**
     `UIColor` used for quote blocks. Default value is dark grey.
     */
    open var quoteColor = UIColor.darkGray
    
    /**
     Quote indentation in points. Default 20.
     */
    open var quoteIndendation : CGFloat = 20
    
    /**
     Dynamic type font text style, default `UIFontTextStyleBody`.
     
     - see: 
       [Text 
       Styles](xcdoc://?url=developer.apple.com/library/ios/documentation/UIKit/Reference/UIFontDescriptor_Class/index.html#//apple_ref/doc/constant_group/Text_Styles)
     */
    open var fontTextStyle : String = UIFontTextStyle.body.rawValue
    
    // MARK: Syntax highlighting
    
    /**
    To customise the appearance of the markdown syntax highlights you should
     subclass this class (or create your own direct `NSTextStorage` subclass)
     and set the customisations in this method implementation. Sends out
     `-textStorage:willProcessEditing`, fixes the attributes, sends out
     `-textStorage:didProcessEditing`, and notifies the layout managers of
     change with the
     `-processEditingForTextStorage:edited:range:changeInLength:invalidatedRange:`
     method.  Invoked from `-edited:range:changeInLength:` or `-endEditing`.
    
    - see:
    [`NSTextStorage`](xcdoc://?url=developer.apple.com/library/ios/documentation/UIKit/Reference/NSTextStorage_Class_TextKit/index.html#//apple_ref/doc/uid/TP40013282)
    */
    override open func processEditing() {
        // removeParagraphAttributes()
        removeWholeAttributes()
        
        Marklight.syntaxColor = syntaxColor
        Marklight.codeFontName = codeFontName
        Marklight.codeColor = codeColor
        Marklight.quoteFontName = quoteFontName
        Marklight.quoteColor = quoteColor
        Marklight.quoteIndendation = quoteIndendation
        Marklight.fontTextStyle = fontTextStyle
        
        Marklight.processEditing(self)
        
        super.processEditing()
    }
    
    // MARK: Initialisers
    
    /**
    The designated initialiser. If you subclass `MarklightTextStorage`, you
     must call the super implementation of this method.
    */
    override public init() {
        super.init()
        observeTextSize()
    }

    /**
    The designated initialiser. If you subclass `MarklightTextStorage`, you must
    call the super implementation of this method.
     */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        observeTextSize()
    }
    
    required public init(itemProviderData data: Data, typeIdentifier: String) throws {
        fatalError("init(itemProviderData:typeIdentifier:) has not been implemented")
    }
    
    /**
    Internal method to register to notifications determined by dynamic type size
    changes and redraw the attributed text with the appropriate text size.
    Currently it works only after the user adds or removes some chars inside the
    `UITextView`.
     */
    func observeTextSize() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            let wholeRange = NSMakeRange(0, (self.string as NSString).length)
            self.invalidateAttributes(in: wholeRange)
            for layoutManager in self.layoutManagers {
                layoutManager.invalidateDisplay(forCharacterRange: wholeRange)
            }
        }
    }
    
    /**
    Designated deinitialised. Never call this directly. We just unregister to
    internal notifications.
     */
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
    // MARK: Reading Text
    
    public var attributedString: NSAttributedString {
        return imp
    }
    
    /**
    Use this method to extract the text from the `UITextView` as plain text.
    
    - returns: The `String` containing the text inside the `UITextView`.
    
    - see:
    [`NSTextStorage`](xcdoc://?url=developer.apple.com/library/ios/documentation/UIKit/Reference/NSTextStorage_Class_TextKit/index.html#//apple_ref/doc/uid/TP40013282)
     */
    override open var string : String {
        return imp.string
    }
    
    /**
    Returns the attributes for the character at a given index.
    The attributes for the character at index.
     
    - parameter index: The index for which to return attributes. This value must
      lie within the bounds of the receiver.
     - parameter aRange: Upon return, the range over which the attributes and
       values are the same as those at index. This range isn’t necessarily the
       maximum range covered, and its extent is implementation-dependent. If you
       need the maximum range, use
       attributesAtIndex:longestEffectiveRange:inRange:. If you don't need this
       value, pass NULL.
     - returns: The attributes for the character at index.     - see:
     [`NSTextStorage`](xcdoc://?url=developer.apple.com/library/ios/documentation/UIKit/Reference/NSTextStorage_Class_TextKit/index.html#//apple_ref/doc/uid/TP40013282)
     */

    
    open override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [String : Any] {
        return imp.attributes(at: location, effectiveRange: range) as [String : AnyObject]
    }
    
    // MARK: Text Editing
    
    /**
    Replaces the characters in the given range with the characters of the given
     string. The new characters inherit the attributes of the first replaced
     character from aRange. Where the length of aRange is 0, the new characters
     inherit the attributes of the character preceding aRange if it has any,
     otherwise of the character following aRange. Raises an NSRangeException if
     any part of aRange lies beyond the end of the receiver’s characters.
    - parameter aRange: A range specifying the characters to replace.
    - parameter aString: A string specifying the characters to replace those in
       aRange.
    - see:
    [`NSTextStorage`](xcdoc://?url=developer.apple.com/library/ios/documentation/UIKit/Reference/NSTextStorage_Class_TextKit/index.html#//apple_ref/doc/uid/TP40013282)
    */
    override open func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        imp.replaceCharacters(in: range, with: str)
        edited([.editedCharacters], range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
    }
    
    /**
    Sets the attributes for the characters in the specified range to the 
    specified attributes. These new attributes replace any attributes previously
    associated with the characters in aRange. Raises an NSRangeException if any
    part of aRange lies beyond the end of the receiver’s characters. To set
    attributes for a zero-length NSMutableAttributedString displayed in a text
    view, use the NSTextView method setTypingAttributes:.
     - parameter attributes: A dictionary containing the attributes to set. 
       Attribute keys can be supplied by another framework or can be custom ones
       you define. For information about where to find the system-supplied
       attribute keys, see the overview section in NSAttributedString Class
       Reference.
     - parameter aRange: The range of characters whose attributes are set.
     - see: 
        [`NSMutableAttributedString`](xcdoc://?url=developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSMutableAttributedString_Class/index.html#//apple_ref/swift/cl/c:objc(cs)NSMutableAttributedString
     )
     - see:
        [`NSTextStorage`](xcdoc://?url=developer.apple.com/library/ios/documentation/UIKit/Reference/NSTextStorage_Class_TextKit/index.html#//apple_ref/doc/uid/TP40013282)
     */
    
    
    open override func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        beginEditing()
        imp.setAttributes(attrs, range: range)
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }
    
    // Remove every attribute to the whole text
    fileprivate func removeParagraphAttributes() {
        let textSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.body).pointSize
        let paragraphRange = (string as NSString).paragraphRange(for: self.editedRange)
        self.removeAttribute(NSForegroundColorAttributeName, range: paragraphRange)
        self.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: textSize), range: paragraphRange)
        self.addAttribute(NSParagraphStyleAttributeName, value: NSMutableParagraphStyle.default, range: paragraphRange)
    }
    
    // Remove every attribute the the paragraph containing the last edit.
    fileprivate func removeWholeAttributes() {
        let textSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.body).pointSize
        let wholeRange = NSMakeRange(0, (self.string as NSString).length)
        self.removeAttribute(NSForegroundColorAttributeName, range: wholeRange)
        self.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: textSize), range: wholeRange)
        self.addAttribute(NSParagraphStyleAttributeName, value: NSMutableParagraphStyle.default, range: wholeRange)
    }
}

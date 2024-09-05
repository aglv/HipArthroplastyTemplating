//
//  ArthroplastyTemplatesWindowController+List.mm
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 08.09.09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplatesWindowController+Templates.h"
#import "ArthroplastyTemplatesWindowController+Private.h"

#import "ArthroplastyTemplateFamily.h"
#import "InfoTxtArthroplastyTemplate.h"
#import "HipArthroplastyTemplating.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/NSFileManager+N2.h>
#pragma clang diagnostic pop

@implementation ArthroplastyTemplatesWindowController (Templates)

- (void)initTemplates {
}

- (void)awakeTemplates {
	[_templates removeAllObjects];
    
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    NSString *temp;
    if ((temp = [[NSBundle bundleForClass:self.class] resourcePath]))
        [paths addObject:temp];
    if ((temp = [[HipArthroplastyTemplating findSystemFolderOfType:kApplicationSupportFolderType forDomain:kUserDomain] stringByAppendingPathComponent:@"OsiriX/HipArthroplastyTemplating"]))
        [paths addObject:temp];
    if ((temp = [[HipArthroplastyTemplating findSystemFolderOfType:kApplicationSupportFolderType forDomain:kLocalDomain] stringByAppendingPathComponent:@"OsiriX/HipArthroplastyTemplating"]))
        [paths addObject:temp];

	for (NSString *path in paths) {
        for (NSString *sub in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL])
            if ([sub hasSuffix:@"Templates"]) {
                NSString *tdpath = [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[path stringByAppendingPathComponent:sub]];
                [_templates addObjectsFromArray:[[self class] templatesAtPath:tdpath]];
                NSString *plistpath = [tdpath stringByAppendingPathComponent:@"_Bounds.plist"];
                if ([NSFileManager.defaultManager fileExistsAtPath:plistpath])
                    [_selections addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:plistpath]];
            }
    }
	
	// fill _families from _templates
	for (unsigned i = 0; i < _templates.count; ++i) {
		ArthroplastyTemplate *templat = _templates[i];
		BOOL included = NO;
		
		for (unsigned i = 0; i < [[_familiesArrayController content] count]; ++i) {
			ArthroplastyTemplateFamily *family = [[_familiesArrayController content] objectAtIndex:i];
			if ([family matches:templat]) {
				[family add:templat];
				included = YES;
				break;
			}
		}
		
		if (included)
			continue;
		
		[_familiesArrayController addObject:[[[ArthroplastyTemplateFamily alloc] initWithTemplate:templat] autorelease]];
	}
	
	//	[_familiesArrayController rearrangeObjects];
	[_familiesTableView reloadData];
}

- (void)deallocTemplates {
}

+ (NSArray *)templatesAtPath:(NSString *)dirpath {
    NSMutableArray *templates = [NSMutableArray array];
    
    NSDictionary *classes = [NSDictionary dictionaryWithObjectsAndKeys:
                             [InfoTxtArthroplastyTemplate class], @"txt",
                             nil];
    
    BOOL isDirectory, exists = [[NSFileManager defaultManager] fileExistsAtPath:dirpath isDirectory:&isDirectory];
    if (exists && isDirectory) {
        NSDirectoryEnumerator *e = [[NSFileManager defaultManager] enumeratorAtPath:dirpath];
        NSString *sub; while (sub = [e nextObject]) {
            NSString *subpath = [dirpath stringByAppendingPathComponent:sub];
            [[NSFileManager defaultManager] fileExistsAtPath:subpath isDirectory:&isDirectory];
            if (!isDirectory && [subpath rangeOfString:@".disabled/"].location == NSNotFound) {
                for (NSString *ext in classes)
                    if ([[subpath pathExtension] isEqualToString:ext])
                        [templates addObjectsFromArray:[[classes objectForKey:ext] templatesFromFileURL:[NSURL fileURLWithPath:subpath isDirectory:NO]]];
            }
        }
    }
    
    return templates;
}

- (ArthroplastyTemplate *)templateAtPath:(NSString *)path {
	for (unsigned i = 0; i < [_templates count]; ++i)
		if ([_templates[i].fileURL.path isEqualToString:path])
			return _templates[i];
	return nil;
}

//-(ArthroplastyTemplate *)templateAtIndex:(int)index {
//	return [[_templatesArrayController arrangedObjects] objectAtIndex:index];	
//}

- (ArthroplastyTemplateFamily *)familyAtIndex:(NSInteger)index {
	if (index < 0 || index >= [_familiesArrayController.arrangedObjects count])
        return nil;
    return [_familiesArrayController.arrangedObjects objectAtIndex:index];
}

- (void)filterTemplates {
    NSMutableArray *or_subs = [NSMutableArray array];
    
    for (NSString *orstr in [_searchField.stringValue componentsSeparatedByString:@"|"]) {
        orstr = [orstr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSMutableArray *and_subs = [NSMutableArray array];
        
        for (NSString *str in [orstr componentsSeparatedByString:@" "]) {
            str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if (!str.length)
                continue;
            
            BOOL no = NO;
            if ([str characterAtIndex:0] == '!') {
                no = YES;
                str = [str substringFromIndex:1];
            }
            
            NSPredicate *subpredicate = [NSPredicate predicateWithFormat:@"((fixation contains[c] %@) OR (group contains[c] %@) OR (manufacturer contains[c] %@) OR (modularity contains[c] %@) OR (name contains[c] %@) OR (patientSide contains[c] %@) OR (surgery contains[c] %@) OR (type contains[c] %@))", str, str, str, str, str, str, str, str];
            if (no)
                subpredicate = [NSCompoundPredicate notPredicateWithSubpredicate:subpredicate];
            
            [and_subs addObject:subpredicate];
        }
        
        if (and_subs.count)
            [or_subs addObject:[NSCompoundPredicate andPredicateWithSubpredicates:and_subs]];
    }
    
    if (or_subs.count == 0)
        [or_subs addObject:[NSPredicate predicateWithValue:YES]];
        
    [_familiesArrayController setFilterPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:or_subs]];

	//	[_familiesArrayController rearrangeObjects];
    [_familiesTableView noteNumberOfRowsChanged];
	//	[self.familiesTableView reloadData];

    [self.window orderFront:self];
}

- (BOOL)setFilter:(NSString *)string {
	_searchField.stringValue = string;
	[self filterTemplates];
	return [_familiesArrayController.arrangedObjects count] > 0;
}

- (IBAction)filterAction:(id)sender {
	[self filterTemplates];
}

@end

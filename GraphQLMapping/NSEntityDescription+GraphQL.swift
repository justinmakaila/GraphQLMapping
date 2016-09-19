import CoreData
import GraphQL
import RemoteMapping


/// Mapping for GraphQL Relationships
protocol GraphQLRelationshipMapping {
    var graphQLRelayConnection: Bool { get }
}

public protocol GraphQLEntity {
    /// The field name representing the entity
    var fieldName: String { get }
    /// The collection name representing a collection of entities
    var collectionName: String { get }
}

private enum MappingKey: String {
    case relayConnection = "GraphQL.RelayConnection"
    case fieldName = "GraphQL.FieldName"
    case collectionName = "GraphQL.CollectionName"
    case customSelectionSet = "GraphQL.CustomSelectionSet"
}

extension NSPropertyDescription {
    public var graphQLPropertyName: String {
        return userInfo?[MappingKey.fieldName.rawValue] as? String ?? remotePropertyName
    }
    
    fileprivate var graphQLCustomSelectionSet: GraphQL.SelectionSet {
        guard let selectionSetString = userInfo?[MappingKey.customSelectionSet.rawValue] as? String
        else {
            return []
        }
        
        let components = selectionSetString.components(separatedBy: " ")
        let selectionSetComponents = Array(components.dropLast().dropFirst())
        
        return selectionSetComponents.map { GraphQL.Field(name: $0) }
    }
}

extension NSRelationshipDescription: GraphQLRelationshipMapping {
    public var graphQLRelayConnection: Bool {
        return userInfo?[MappingKey.relayConnection.rawValue] != nil
    }
}

extension NSEntityDescription: GraphQLEntity {
    public var fieldName: String {
        return (userInfo?[MappingKey.fieldName.rawValue] as? String ?? name ?? managedObjectClassName)
    }
    
    public var collectionName: String {
        return userInfo?[MappingKey.collectionName.rawValue] as? String ?? "\(fieldName)s"
    }
}

public extension NSEntityDescription {
    /// Returns a selection set representing the entity.
    public func selectionSet(_ parent: NSEntityDescription? = nil, includeRelationships: Bool = true, excludeKeys: Set<String> = [], customFields: [String: GraphQL.Field] = [:]) -> GraphQL.SelectionSet {
        return remoteProperties
            .filter { propertyDescription in
                return !excludeKeys.contains(propertyDescription.graphQLPropertyName)
            }
            .flatMap { propertyDescription -> GraphQL.Field? in
                let remoteKey = propertyDescription.graphQLPropertyName
                
                if let customField = customFields[remoteKey] {
                    return customField
                }
                
                if let attributeDescription = propertyDescription as? NSAttributeDescription {
                    return fieldForAttribute(attributeDescription)
                } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription , (includeRelationships == true) {
                    guard let destinationEntity = relationshipDescription.destinationEntity
                    else {
                        return nil
                    }
                    
                    let isValidRelationship = !(parent != nil && (parent == destinationEntity) && !relationshipDescription.isToMany)
                    
                    if isValidRelationship {
                        if relationshipDescription.isToMany {
                            return fieldForToManyRelationship(destinationEntity, relationshipName: remoteKey, includeRelationships: includeRelationships, parent: self, relayConnection: relationshipDescription.graphQLRelayConnection)
                        } else {
                            return fieldForToOneRelationship(destinationEntity, relationshipName: remoteKey, includeRelationships: includeRelationships, parent: self)
                        }
                    }
                }
                
                return nil
        }
    }
    
    fileprivate func fieldForAttribute(_ attribute: NSAttributeDescription) -> GraphQL.Field {
        return GraphQL.Field(name: attribute.graphQLPropertyName, selectionSet: attribute.graphQLCustomSelectionSet)
    }
    
    /// Returns a field representing a to-one relationship
    fileprivate func fieldForToOneRelationship(_ entity: NSEntityDescription, relationshipName: String, includeRelationships: Bool = true, parent: NSEntityDescription?) -> GraphQL.Field {
        return GraphQL.Field(name: relationshipName, selectionSet: entity.selectionSet(parent, includeRelationships: includeRelationships))
    }
    
    /// Returns a field representing a to-many relationship
    fileprivate func fieldForToManyRelationship(_ entity: NSEntityDescription, relationshipName: String, includeRelationships: Bool = true, parent: NSEntityDescription?, relayConnection: Bool = false) -> GraphQL.Field? {
        if relayConnection {
            return GraphQL.Field(name: relationshipName, selectionSet: [
                    GraphQL.Field(name: "edges", selectionSet: [
                        GraphQL.Field(name: "node", selectionSet: entity.selectionSet(parent, includeRelationships: includeRelationships))
                    ])
                ]
            )
        } else {
            return GraphQL.Field(name: relationshipName, selectionSet: entity.selectionSet(parent, includeRelationships: includeRelationships))
        }
    }
}

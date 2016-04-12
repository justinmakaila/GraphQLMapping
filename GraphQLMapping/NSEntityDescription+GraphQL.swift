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
    case RelayConnection = "GraphQL.RelayConnection"
    case FieldName = "GraphQL.FieldName"
    case CollectionName = "GraphQL.CollectionName"
    case CustomSelectionSet = "GraphQL.CustomSelectionSet"
}

extension NSPropertyDescription {
    public var graphQLPropertyName: String {
        return userInfo?[MappingKey.FieldName.rawValue] as? String ?? remotePropertyName
    }
    
    private var graphQLCustomSelectionSet: GraphQL.SelectionSet {
        guard let selectionSetString = userInfo?[MappingKey.CustomSelectionSet.rawValue] as? String
        else {
            return []
        }
        
        let components = selectionSetString.componentsSeparatedByString(" ")
        let selectionSetComponents = Array(components.dropLast().dropFirst())
        
        return selectionSetComponents.map { GraphQL.Field(name: $0) }
    }
}

extension NSRelationshipDescription: GraphQLRelationshipMapping {
    public var graphQLRelayConnection: Bool {
        return userInfo?[MappingKey.RelayConnection.rawValue] != nil
    }
}

extension NSEntityDescription: GraphQLEntity {
    public var fieldName: String {
        return (userInfo?[MappingKey.FieldName.rawValue] as? String ?? name ?? managedObjectClassName)
    }
    
    public var collectionName: String {
        return userInfo?[MappingKey.CollectionName.rawValue] as? String ?? "\(fieldName)s"
    }
}

public extension NSEntityDescription {
    /// Returns a selection set representing the entity.
    func selectionSet(parent: NSEntityDescription? = nil, includeRelationships: Bool = true, excludeKeys: Set<String> = [], customFields: [String: GraphQL.Field] = [:]) -> GraphQL.SelectionSet {
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
                } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription where (includeRelationships == true) {
                    guard let destinationEntity = relationshipDescription.destinationEntity
                    else {
                        return nil
                    }
                    
                    let isValidRelationship = !(parent != nil && (parent == destinationEntity) && !relationshipDescription.toMany)
                    
                    if isValidRelationship {
                        if relationshipDescription.toMany {
                            return fieldForToManyRelationship(destinationEntity, relationshipName: remoteKey, includeRelationships: includeRelationships, parent: self, relayConnection: relationshipDescription.graphQLRelayConnection)
                        } else {
                            return fieldForToOneRelationship(destinationEntity, relationshipName: remoteKey, includeRelationships: includeRelationships, parent: self)
                        }
                    }
                }
                
                return nil
        }
    }
    
    private func fieldForAttribute(attribute: NSAttributeDescription) -> GraphQL.Field {
        return GraphQL.Field(name: attribute.graphQLPropertyName, selectionSet: attribute.graphQLCustomSelectionSet)
    }
    
    /// Returns a field representing a to-one relationship
    private func fieldForToOneRelationship(entity: NSEntityDescription, relationshipName: String, includeRelationships: Bool = true, parent: NSEntityDescription?) -> GraphQL.Field {
        return GraphQL.Field(name: relationshipName, selectionSet: entity.selectionSet(parent, includeRelationships: includeRelationships))
    }
    
    /// Returns a field representing a to-many relationship
    private func fieldForToManyRelationship(entity: NSEntityDescription, relationshipName: String, includeRelationships: Bool = true, parent: NSEntityDescription?, relayConnection: Bool = false) -> GraphQL.Field? {
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
import CoreData
import GraphQL
import RemoteMapping


public enum RelationshipType: Int {
    case None
    case Array
}

/// Mapping for GraphQL Relationships
protocol GraphQLRelationshipMapping {
    var graphQLRelayConnection: Bool { get }
}

public protocol GraphQLEntity {
    var fieldName: String { get }
    var collectionName: String { get }
    var selectionSet: GraphQL.SelectionSet { get }
}

private enum MappingKeys: String {
    case RelayConnection = "GraphQL.RelayConnection"
    case FieldName = "GraphQL.FieldName"
    case CollectionName = "GraphQL.CollectionName"
}

extension NSPropertyDescription {
    var graphQLPropertyName: String {
        return userInfo?[MappingKeys.FieldName.rawValue] as? String ?? remotePropertyName
    }
}

extension NSRelationshipDescription: GraphQLRelationshipMapping {
    var graphQLRelayConnection: Bool {
        return userInfo?[MappingKeys.RelayConnection.rawValue] != nil
    }
}

extension NSEntityDescription: GraphQLEntity {
    public var fieldName: String {
        return userInfo?[MappingKeys.FieldName.rawValue] as? String ?? name!.lowercaseString
    }
    
    public var collectionName: String {
        return userInfo?[MappingKeys.CollectionName.rawValue] as? String ?? "\(fieldName)s"
    }
    
    public var selectionSet: GraphQL.SelectionSet {
        return selectionSet()
    }
}

public extension NSEntityDescription {
    /// Returns a selection set representing the entity.
    /// If `parent` is provided, this method will not include any properties which reference the parent.
    func selectionSet(parent: NSEntityDescription? = nil, relationshipType: RelationshipType = .Array) -> GraphQL.SelectionSet {
        return remoteProperties
            .flatMap { propertyDescription -> GraphQL.Field? in
                let remoteKey = propertyDescription.graphQLPropertyName
                
                if propertyDescription is NSAttributeDescription {
                    return GraphQL.Field(name: remoteKey)
                } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription where (relationshipType != .None) {
                    guard let destinationEntity = relationshipDescription.destinationEntity
                        else {
                            return nil
                    }
                    
                    let isValidRelationship = !(parent != nil && (parent == destinationEntity) && !relationshipDescription.toMany)
                    if isValidRelationship {
                        if relationshipDescription.toMany {
                            return fieldForToManyRelationship(destinationEntity, relationshipName: remoteKey, relationshipType: relationshipType, parent: self, relayConnection: relationshipDescription.graphQLRelayConnection)
                        } else {
                            return fieldForToOneRelationship(destinationEntity, relationshipName: remoteKey, relationshipType: relationshipType, parent: self)
                        }
                    }
                    
                    return GraphQL.Field(name: remoteKey)
                }
                
                return nil
        }
    }
    
    private func fieldForToOneRelationship(entity: NSEntityDescription, relationshipName: String, relationshipType: RelationshipType, parent: NSEntityDescription?) -> GraphQL.Field {
        return GraphQL.Field(name: relationshipName, selectionSet: entity.selectionSet(parent, relationshipType: relationshipType))
    }
    
    private func fieldForToManyRelationship(entity: NSEntityDescription, relationshipName: String, relationshipType: RelationshipType, parent: NSEntityDescription?, relayConnection: Bool = false) -> GraphQL.Field? {
        if relayConnection {
            return GraphQL.Field(name: relationshipName, selectionSet: [
                    GraphQL.Field(name: "edges", selectionSet: [
                        GraphQL.Field(name: "node", selectionSet: entity.selectionSet(parent, relationshipType: relationshipType))
                    ])
                ]
            )
        } else {
            return GraphQL.Field(name: relationshipName, selectionSet: entity.selectionSet(parent, relationshipType: relationshipType))
        }
    }
}
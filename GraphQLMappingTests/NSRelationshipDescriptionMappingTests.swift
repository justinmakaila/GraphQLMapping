import XCTest
import CoreData
import GraphQL

@testable
import GraphQLMapping


class NSRelationshipDescriptionMappingTests: GraphQLMappingTestCase {
    func test_NSRelationshipDescriptionGraphQL_ProvidesRelayConnectionRelationship() {
        let user = entityForName("User")
        let propertiesByName = user.propertiesByName
        
        guard let petsRelationship = propertiesByName["pets"] as? NSRelationshipDescription
        else {
            XCTAssert(false, "Could not get \"Pets\" relationship.")
            return
        }
        
        XCTAssertTrue(petsRelationship.graphQLRelayConnection)
    }
}

using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleanArchitecture.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddBoardsNavigationToWorkspace : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "WorkspaceId1",
                table: "Boards",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Boards_WorkspaceId1",
                table: "Boards",
                column: "WorkspaceId1");

            migrationBuilder.AddForeignKey(
                name: "FK_Boards_Workspaces_WorkspaceId1",
                table: "Boards",
                column: "WorkspaceId1",
                principalTable: "Workspaces",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Boards_Workspaces_WorkspaceId1",
                table: "Boards");

            migrationBuilder.DropIndex(
                name: "IX_Boards_WorkspaceId1",
                table: "Boards");

            migrationBuilder.DropColumn(
                name: "WorkspaceId1",
                table: "Boards");
        }
    }
}

using System;
using CleanArchitecture.Infrastructure.Contexts;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace CleanArchitecture.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260327191500_AddTaskCategoryAndUserCategoryScores")]
    public partial class AddTaskCategoryAndUserCategoryScores : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "WorkCategory",
                table: "BoardTasks",
                type: "character varying(64)",
                maxLength: 64,
                nullable: false,
                defaultValue: "other");

            migrationBuilder.AddColumn<DateTime>(
                name: "WorkCategoryClassifiedAt",
                table: "BoardTasks",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "WorkCategoryConfidence",
                table: "BoardTasks",
                type: "double precision",
                nullable: false,
                defaultValue: 0d);

            migrationBuilder.CreateTable(
                name: "UserCategoryScores",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserId = table.Column<string>(type: "text", nullable: true),
                    Category = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    CompletedTasks = table.Column<int>(type: "integer", nullable: false),
                    OnTimeCompletedTasks = table.Column<int>(type: "integer", nullable: false),
                    TotalCompletionHours = table.Column<double>(type: "double precision", nullable: false),
                    AverageCompletionHours = table.Column<double>(type: "double precision", nullable: false),
                    Score = table.Column<double>(type: "double precision", nullable: false),
                    LastCompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    LastTaskId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserCategoryScores", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BoardTasks_BoardId_WorkCategory",
                table: "BoardTasks",
                columns: new[] { "BoardId", "WorkCategory" });

            migrationBuilder.CreateIndex(
                name: "IX_UserCategoryScores_Category",
                table: "UserCategoryScores",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_UserCategoryScores_UserId_Category",
                table: "UserCategoryScores",
                columns: new[] { "UserId", "Category" },
                unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserCategoryScores");

            migrationBuilder.DropIndex(
                name: "IX_BoardTasks_BoardId_WorkCategory",
                table: "BoardTasks");

            migrationBuilder.DropColumn(
                name: "WorkCategory",
                table: "BoardTasks");

            migrationBuilder.DropColumn(
                name: "WorkCategoryClassifiedAt",
                table: "BoardTasks");

            migrationBuilder.DropColumn(
                name: "WorkCategoryConfidence",
                table: "BoardTasks");
        }
    }
}
